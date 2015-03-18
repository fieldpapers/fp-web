class Paper
  # from http://www.papersizes.org/
  PAPER_SIZES = {
    "4a0"          => [66.2, 93.6],
    "2a0"          => [46.8, 66.2],
    "a0"           => [33.1, 46.8],
    "a1"           => [23.4, 33.1],
    "a2"           => [16.5, 23.4],
    "a3"           => [11.7, 16.5],
    "a4"           => [8.3, 11.6],
    "a5"           => [5.8, 8.3],
    "a6"           => [4.1, 5.8],
    "a7"           => [2.9, 4.1],
    "a8"           => [2.0, 2.9],
    "a9"           => [1.5, 2.0],
    "a10"          => [1.0, 1.5],
    "letter"       => [8.5, 11],
    "legal"        => [8.5, 14],
    "junior legal" => [5, 8],
    "tabloid"      => [11, 17],
  }

  # paper sizes (in inches)
  def self.size(format)
    PAPER_SIZES[format.downcase]
  end

  def self.canvas_size(format, orientation)
    paper_size = self.size(format)

    paper_size = paper_size.reverse if orientation == "landscape"

    # TODO extract margins
    [paper_size[0] - 1, paper_size[1] - 1.5]
  end
end
