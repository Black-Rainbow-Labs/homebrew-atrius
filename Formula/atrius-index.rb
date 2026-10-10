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
  version "0.2.0"
  license any_of: ["MIT", "Apache-2.0"]

  on_macos do
    url "https://blackrainbowlabs.com/downloads/atrius-index/atrius-index-0.2.0-universal-apple-darwin.tar.gz"
    sha256 "2019413ffb8fd3b22966a3105a86139b5fa685241621581d6b12a96e22d42a5e"
  end

  on_linux do
    on_intel do
      url "https://blackrainbowlabs.com/downloads/atrius-index/atrius-index-0.2.0-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "49083bb13731be47a7abe2043e0ad65816a44503bb44f2633d6cc9e3e57f3dea"
    end
    on_arm do
      url "https://blackrainbowlabs.com/downloads/atrius-index/atrius-index-0.2.0-aarch64-unknown-linux-gnu.tar.gz"
      sha256 "a18c6196ca71d5024fab213911f5d8eb20b7d81e431393ac41f0b596be47468a"
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
