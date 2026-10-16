# The Homebrew formula, for the tap `Black-Rainbow-Labs/homebrew-atrius`.
#
#   brew install black-rainbow-labs/atrius/atrius-index
#
# packaging/ship.ps1 fills in the version and the three checksums from dist/SHA256SUMS and pushes the
# result to the tap as Formula/atrius-index.rb, so the numbers are never typed by hand. The archives are
# downloaded from blackrainbowlabs.com, because the source repository is private and so are its GitHub
# release assets.
class AtriusIndex < Formula
  desc "Code index for agents: ripgrep's exact results from an index, definitions and an MCP server"
  homepage "https://blackrainbowlabs.com/lab"
  version "0.3.0"
  license any_of: ["MIT", "Apache-2.0"]

  on_macos do
    url "https://blackrainbowlabs.com/downloads/atrius-index/atrius-index-0.3.0-universal-apple-darwin.tar.gz"
    sha256 "3a976abbe6e9b5c50afac0553550a06a993bb01e6de59aa969fa2be9aed1e0f8"
  end

  on_linux do
    on_intel do
      url "https://blackrainbowlabs.com/downloads/atrius-index/atrius-index-0.3.0-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "6dee690a6e7b66e630e24956d76c2ca00c93f4096d51070c7d9069887eee8424"
    end
    on_arm do
      url "https://blackrainbowlabs.com/downloads/atrius-index/atrius-index-0.3.0-aarch64-unknown-linux-gnu.tar.gz"
      sha256 "ca9a6b4ebdae72146747003984a985e903da0d29b5d3576ee5280a1ea1894877"
    end
  end

  def install
    bin.install "bin/atrius", "bin/atrius-mcp"
    doc.install "README.md", "CHANGELOG.md"
    doc.install "docs"
  end

  def caveats
    <<~CAVEATS
      To give an AI agent Atrius's queries:
        claude mcp add atrius -- #{opt_bin}/atrius-mcp

      To keep a checkout indexed at all times:
        atrius watch add ~/code/my-project && atrius service install
    CAVEATS
  end

  test do
    (testpath/"src/lib.rs").write "pub fn retry_write() -> bool {\n    true\n}\n"
    system "git", "init", "--quiet", testpath
    ENV["ATRIUS_INDEX_CACHE"] = (testpath/"cache").to_s
    ENV["ATRIUS_IDLE_MINUTES"] = "1"
    found = shell_output("#{bin}/atrius find retry_write --root #{testpath}")
    assert_match "src/lib.rs", found
    system bin/"atrius", "stop", "--root", testpath
    handshake = [
      %({"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18",) +
        %("capabilities":{},"clientInfo":{"name":"brew-test","version":"1"}}}),
      %({"jsonrpc":"2.0","method":"notifications/initialized"}),
      %({"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}})
    ].join("\n")
    listed = pipe_output("#{bin}/atrius-mcp --root #{testpath}", "#{handshake}\n")
    assert_match "atrius_search", listed
  end
end
