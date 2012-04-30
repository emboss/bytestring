class ByteString
  module BasicByteString
    include Enumerable

    def clone
      ByteString.new(@inner)
    end

    def [](index)
      slice(index)
    end

    def slice(num_or_range, num=nil)
      return slice_n(num_or_range, num) if num
      slice = @inner.slice(num_or_range)
      return nil unless slice
      return slice.ord if slice.size == 1
      ByteString.new(slice)
    end 

    def ^(other)
      bitwise(:^, other)
    end

    def &(other)
      bitwise(:&, other)
    end

    def |(other)
      bitwise(:|, other)
    end

    def ~
      ByteString.new("".tap do |result|
        each { |b| result << 255 - b }
      end)
    end

    def size
      @inner.size
    end

    def ord
      raise RuntimeError.new("Size is not 1") unless size == 1
      @inner.ord
    end

    def each(&blk)
      return @inner.each_byte unless block_given?
      @inner.each_byte(&blk)
    end

    def to_s
      String.new(@inner)
    end

    def to_hex
      @inner.unpack("H*")[0]
    end

    def ==(other)
      return false unless size == other.size
      each.each_with_index do |b, i|
        return false unless b == other[i]
      end
      true
    end

    private

    def slice_n(from, to)
      slice = @inner.slice(from, to)
      return nil unless slice
      ByteString.new(slice)
    end

    def bitwise(operator, other)
      raise RuntimeError.new("Sizes are different. #{size}, #{other.size}") unless size == other.size
      ByteString.new("".tap do |result|
        each.each_with_index { |b, i| result << (b.send(operator, other[i])) }
      end)
    end
  end

  include BasicByteString

  def initialize(string=nil)
    @inner = string ? String.new(string.to_s) : ""
    @inner.force_encoding(Encoding::BINARY)
  end

  def self.from_hex(string)
    ByteString.new([string].pack("H*"))
  end

  def self.read(io)
    ByteString.new(io.read.force_encoding(Encoding::BINARY))
  end

  def []=(index, b)
    @inner.setbyte(index, b)
  end 

  def slice!(num_or_range, num=nil)
    raise NotImplementedError.new
  end

  def concat(other)
    if other.respond_to?(:chr)
      @inner << other
      return self
    end

    other.each do |b|
      @inner << b
    end
    self
  end
  alias :<< :concat

  class Immutable
    include BasicByteString

    def initialize(io)
      @inner = io.read.force_encoding(Encoding::BINARY)
    end

    def erase
      @inner.replace("\x00" * size)
    end
  end
end
