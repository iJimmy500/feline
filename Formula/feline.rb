class Feline < Formula
  desc "Small, fast command-line tools for your Mac"
  homepage "https://github.com/iJimmy500/feline"
  version "1.2.0"

  url "https://github.com/iJimmy500/feline/releases/download/v1.2.0/feline-1.2.0-macos.tar.gz"
  sha256 "PLACEHOLDER"

  # feline works without these, but they unlock extra capabilities
  depends_on "ffmpeg"      => :optional
  depends_on "yt-dlp"      => :optional
  depends_on "imagemagick" => :optional
  depends_on "pandoc"      => :optional

  def install
    # The tarball ships a pre-built universal binary — just install everything
    bin.install "feline"
    bin.install Dir["feline-*"]
  end

  def caveats
    s = <<~EOS
      feline is ready. Run:
        feline --help

      Optional tools add extra capabilities:
        brew install ffmpeg yt-dlp imagemagick pandoc
    EOS
    s
  end

  test do
    assert_match "feline", shell_output("#{bin}/feline --help 2>&1")
  end
end
