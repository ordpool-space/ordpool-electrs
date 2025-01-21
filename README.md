# Ordpool - Electrs backend API

A block chain index engine and HTTP API written in Rust based on 
[romanz/electrs](https://github.com/romanz/electrs),
[Blockstream/electrs](https://github.com/Blockstream/electrs) and
[mempool/electrs](https://github.com/mempool/electrs).

Used as the backend for the [Ordpool block explorer](https://github.com/ordpool-space/ordpool) powering [ordpool.space](https://ordpool.space/).

<!-- API documentation [is available here](https://mempool.space/docs/api/rest). -->

Documentation for the database schema and indexing process [is available here](doc/schema.md).

### Installing & indexing

Install Rust, Bitcoin Core <!--(no `txindex` needed)--> and the `clang` and `cmake` packages.  
Hint: Add `txindex` so that Bitcoin Core can also be used to index via `ord`.

Example with homebrew:

```bash
brew install rust
rustc --version
sudo apt install libclang-dev clang
```

See also https://github.com/ordpool-space/cat21-ord/blob/index-cat21/docs-cat21/0-developer-howto.md

Then clone the repo:

```bash
$ git clone https://github.com/ordpool-space/ordpool-electrs
$ cd ordpool-electrs
$ git checkout ordpool
```

Execute with light index (good enough for development):

```bash
$ cargo run --release --bin electrs -- -v --daemon-dir ~/.bitcoin --lightmode
```

Logging Levels in `electrs`:

1. **`-v` (Minimal Logging)**:
   - Logs basic operational details.
   - Suitable for production to keep logs small and focused on critical information.

2. **`-vv` (Moderate Logging)**:
   - Adds more detailed logs, including non-critical operations.
   - Useful for debugging common issues without overwhelming log output.

3. **`-vvv` (Detailed Logging)**:
   - Logs a lot of information about internal operations, including debug-level messages.
   - Useful for deep debugging or troubleshooting complex issues.

4. **`-vvvv` (Maximum Verbosity)**:
   - Logs everything, including trace-level messages.
   - Generates massive amounts of data, including details of nearly every function and operation.


Execute with FULL index:

```bash
$ cargo run --release --bin electrs -- -v --daemon-dir ~/.bitcoin
```

If you want start all over again, simply delete the database directory:

```bash
rm -rf ./db/mainnet
```

Stopping the daemon:

```bash
pkill -9 electrs
```

If indexing is still ongoing, wait until it's complete.
Verify electrs is actually binding and ready to serve responses:

```bash
curl http://127.0.0.1:3000/blocks/tip/height
```

### Run as a daemon (simple server for development)

You can also manage the server (for development!) via `systemd`.  
Pre-compile the binary first!

1. **Pre-compile the electrs binary:**
   Navigate to the `ordpool-electrs` directory and build the binary.

   ```bash
   cargo build --release --bin electrs
   ``` 

2. **Enable and Start the Service**:
   `systemd` expects service files to be in `/etc/systemd/system/`. 
   Move your `electrs.service` file there:
   Reload `systemd` to register the updated service file and start the service.

   ```bash
   sudo cp ./ordpool-dev/electrs.service /etc/systemd/system/
   sudo systemctl daemon-reload
   sudo systemctl enable electrs
   sudo systemctl start electrs
   ```

3. **Check the Service Status**:
   Verify that the `electrs` service is running without errors.

   ```bash
   sudo systemctl status electrs
   ```

4. **Log Management:**
   To view logs for the `electrs` service.  
   Full log history:

   ```bash
   sudo journalctl -u electrs
   ```
   Real-time log output:

   ```bash
   sudo journalctl -u electrs -f
   ```

   To check how much space all `systemd` log files (managed by `journald`) are consuming, you can use the following command:

   ```
   sudo journalctl --disk-usage
   ```

   For example, to retain only 500 MB of logs:

   ```
   sudo journalctl --vacuum-size=500M
   ```

### Documentation

See [electrs's original documentation](https://github.com/romanz/electrs/blob/master/doc/usage.md) for more detailed instructions.
Note that our indexes are incompatible with electrs's and has to be created separately.

The indexes require 1.3TB of storage after running compaction (as of October 2023), but you'll need to have
free space of about double that available during the index compaction process.
Creating the indexes should take a few hours on a beefy machine with high speed NVMe SSD(s).

### Light mode

For personal or low-volume use, you may set `--lightmode` to reduce disk storage requirements
by roughly 50% at the cost of slower and more expensive lookups.

With this option set, raw transactions and metadata associated with blocks will not be kept in rocksdb
(the `T`, `X` and `M` indexes),
but instead queried from bitcoind on demand.

### Notable changes from Electrs:

- HTTP REST API in addition to the Electrum JSON-RPC protocol, with extended transaction information
  (previous outputs, spending transactions, script asm and more).

- Extended indexes and database storage for improved performance under high load:

  - A full transaction store mapping txids to raw transactions is kept in the database under the prefix `t`.
  - An index of all spendable transaction outputs is kept under the prefix `O`.
  - An index of all addresses (encoded as string) is kept under the prefix `a` to enable by-prefix address search.
  - A map of blockhash to txids is kept in the database under the prefix `X`.
  - Block stats metadata (number of transactions, size and weight) is kept in the database under the prefix `M`.

  With these new indexes, bitcoind is no longer queried to serve user requests and is only polled
  periodically for new blocks and for syncing the mempool.

- Support for Liquid and other Elements-based networks, including CT, peg-in/out and multi-asset.
  (requires enabling the `liquid` feature flag using `--features liquid`)

### CLI options

In addition to electrs's original configuration options, a few new options are also available:

- `--http-addr <addr:port>` - HTTP server address/port to listen on (default: `127.0.0.1:3000`).
- `--lightmode` - enable light mode (see above)
- `--cors <origins>` - origins allowed to make cross-site request (optional, defaults to none).
- `--address-search` - enables the by-prefix address search index.
- `--index-unspendables` - enables indexing of provably unspendable outputs.
- `--utxos-limit <num>` - maximum number of utxos to return per address.
- `--electrum-txs-limit <num>` - maximum number of txs to return per address in the electrum server (does not apply for the http api).
- `--electrum-banner <text>` - welcome banner text for electrum server.

Additional options with the `liquid` feature:
- `--parent-network <network>` - the parent network this chain is pegged to.

Additional options with the `electrum-discovery` feature:
- `--electrum-hosts <json>` - a json map of the public hosts where the electrum server is reachable, in the [`server.features` format](https://electrumx.readthedocs.io/en/latest/protocol-methods.html#server.features).
- `--electrum-announce` - announce the electrum server on the electrum p2p server discovery network.

See `$ cargo run --bin electrs -- --help` for the full list of options.

## License

MIT
