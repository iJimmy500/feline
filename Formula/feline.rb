class Feline < Formula
  desc "Small, fast command-line tools for your Mac"
  homepage "https://github.com/iJimmy500/feline"
  version "1.0.0"

  # ← Update URL and sha256 after running release.sh and uploading to GitHub
  url "https://github.com/iJimmy500/feline/releases/download/v1.0.0/feline-1.0.0-macos.tar.gz"
  sha256 "f8c273cf972dab5a59a1d04565314ecd31237db7bebfdbf77159837503cfb69b"

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
