require 'rspec'
require 'stringio'
require 'bytestring'

describe ByteString do
  let(:string) { ByteString.new("letest") }
  let(:utf8) { [%w{ C3 A4 }.join('')].pack('H*').force_encoding(Encoding::UTF_8) }

  describe "#new" do

    it "accepts no arguments" do
      -> { ByteString.new }.should_not raise_error
    end

    context "accepts binary Strings" do
      it { -> { ByteString.new("\x00\x01\x02") }.should_not raise_error }  
      it { -> { ByteString.new("plain ASCII text") }.should_not raise_error }  
    end

    it "accepts Strings with an associated encoding" do
      -> { ByteString.new(utf8) }.should_not raise_error
    end

    it "accepts other ByteStrings and copies their contents" do
      s = ByteString.new(string)
      s[2] = "r".ord
      s.to_s.should == "lerest"
      string.to_s.should == "letest"
    end

    it "accepts any Object that responds to to_s" do
      o = Object.new
      s = ByteString.new(o)
      s.to_s.should == o.to_s
    end
  end

  describe "self.from_hex" do
    it "creates a ByteString by converting a hex string to its byte representation" do
      s = ByteString.from_hex("c0ffeebabe")
      s.should be_an_instance_of ByteString
      s.to_s.should == "\xc0\xff\xee\xba\xbe"
    end
  end

  describe "self.read" do
    it "reads a ByteString from an IO by fully consuming it" do
      str = "abc" * 1000
      io = StringIO.new(str)
      s = ByteString.read(io)
      s1 = s.to_s
      s1.encoding.should == Encoding::BINARY
      s1.to_s.should == str
    end
  end 

  describe "#==" do
    context "equality is determined by having equal length and equal contents" do
      context "when equal" do
        let(:other) { ByteString.new("letest") }
        it { (string == other).should be_true }
      end

      context "different length" do
        it { (string == ByteString.new("letest2")).should be_false }
      end

      context "different content" do
        it { (string == ByteString.new("lerest")).should be_false }
      end
    end
  end

  describe "#ord" do
    it "returns the byte representation when containing only a single element" do
      ByteString.new("l").ord.should == "l".ord
    end

    it "raises when the ByteString consists of more than one byte" do
      -> { string.ord }.should raise_error
    end
  end
    
  describe "#[]" do
    context "takes a single Fixnum argument and returns the byte at that position" do
      it "starts indexing at 0" do
        string[0].should == "l".ord
      end

      it "returns nil on out of bounds access" do
        string[20].should be_nil
      end
    end
  end

  describe "#[]==" do
    context "takes a Fixnum index and a byte to be set at that index" do
      it "overwrites the byte at that position" do
        s = ByteString.new(string)
        s[2] = "r".ord
        s.to_s.should == "lerest"
      end
    end
  end

  describe "#slice" do
    context "single Fixnum argument" do
      it "returns the byte at that position" do
        string.slice(0).should == "l".ord
      end

      it "returns nil if no byte exists at that position" do
        string.slice(20).should be_nil
      end
    end

    context "returns a new ByteString representing a given range" do
      it "when it exists" do
        bs = string.slice(2..6)
        bs.should be_an_instance_of ByteString
        bs.to_s.should == "test"
      end

      it "returns the maximally available substring if the range is partially out of bounds" do
        string.slice(2..20).to_s.should == "test"
      end
      
      it "returns nil if the range is completely out of bounds" do
        string.slice(20..40).should be_nil
      end
    end

    context "returns a new ByteString when given a start offset and a length" do
      it "when it exists" do
        bs = string.slice(2, 4)
        bs.should be_an_instance_of ByteString
        bs.to_s.should == "test"
      end

      it "returns the maximally available substring if the specified range is partially out of bounds" do
        string.slice(2, 20).to_s.should == "test"
      end
      
      it "returns nil if the specified range is completely out of bounds" do
        string.slice(20, 40).should be_nil
      end
    end
  end

  describe "#concat" do
    it "concatenates another ByteString and returns the modified result" do
      s = ByteString.new(string)
      s.concat(string).to_s.should == string.to_s * 2
      s.to_s.should == string.to_s * 2
    end

    it "is aliased with '<<'" do
      s = ByteString.new(string)
      s << string
      s.to_s.should == string.to_s * 2
    end

    it "allows to add single bytes" do
      s = ByteString.new(string)
      s << "e".ord
      s << "r".ord
      s.to_s.should == "letester"
    end

    it "allows to subsequently fill a ByteString from scratch" do
      s = ByteString.new
      s << "t".ord
      s << "e".ord
      s << "s".ord
      s << "t".ord
      s.to_s.should == "test"
    end
  end

  describe "bitwise operators" do
    context "combine two equally-sized ByteStrings and return the result" do
      let(:s1) { ByteString.new("\x00\xff") }
      let(:s2) { ByteString.new("\xff\x00") }
      
      it "^" do 
        s = s1 ^ s2
        s.should be_an_instance_of ByteString
        s.to_s.should == "\xff\xff"
        (s ^ s).to_s.should == "\x00\x00"
      end

      it "&" do 
        s = s1 & s2
        s.should be_an_instance_of ByteString
        s.to_s.should == "\x00\x00"
      end

      it "|" do 
        s = s1 ^ s2
        s.should be_an_instance_of ByteString
        s.to_s.should == "\xff\xff"
        (s | s).to_s.should == "\xff\xff"
      end

      context "~" do
        it "multiple bytes" do
          s = ~s1
          s.to_s.should == s2.to_s
        end

        it "single byte" do
          (~ByteString.new("\xf0")).to_s.should == "\x0f"
          (~ByteString.new("\x14")).to_s.should == "\xeb"
        end
      end

      it "raises an error when the lengths differ" do
        -> { s1 ^ string }.should raise_error
        -> { s1 & string }.should raise_error
        -> { s1 | string }.should raise_error
      end
    end
  end

  describe "#each" do
    it "takes a block and yields each byte at a time" do
      s = ""
      string.each do |b|
        s << b
      end
      s.should == string.to_s
    end

    it "includes Enumerable" do
      string.map { |b| b.chr }.join("").should == string.to_s
    end

    it "returns an Enumerator for the individual bytes if no block is given" do
      enum = string.each
      enum.map { |b| b.chr }.join("").should == string.to_s
    end
  end

  describe "#to_s" do
    context "returns a String with Encoding::BINARY" do
      context "when created from a default String" do
        it { string.to_s.encoding.should == Encoding::BINARY }
      end

      context "when created from a String with an associated encoding" do
        it do
          s = ByteString.new(utf8).to_s
          s.encoding.should == Encoding::BINARY
          s.should == "\xc3\xa4"
        end
      end
    end
  end

  describe "#to_hex" do
    it "returns a hex string representing the individual bytes" do
      s = ByteString.new("\xc0\xff\xee\xba\xbe")
      s.to_hex.should == "c0ffeebabe"
    end
  end
end

describe ByteString::Immutable do
  let(:immutable) { ByteString::Immutable }
  let(:test) { "letest" }

  def new_immutable(string)
    immutable.new(StringIO.new(string))
  end

  describe "#new" do
    it "accepts an IO only" do
      s = new_immutable(test)
      s.should be_an_instance_of ByteString::Immutable
    end

    it "rejects Strings" do
      -> { immutable.new(test) }.should raise_error
    end
  end

  describe "#erase" do
    it "clears the contents of the ByteString and overwrites them with 0s in memory" do
      s = new_immutable(test)
      s.should == ByteString.new(test)
      s.erase
      s.should == ByteString.new("\x00\x00\x00\x00\x00\x00")
    end
  end

  describe "does not allow any modifications that would alter its contents" do
    let(:string) { new_immutable(test) }
    
    context "#[]" do
      it { -> { string[0] = 42 }.should raise_error }
    end
  end

  describe "does not leak anything about its contents" do
    let(:string) { new_immutable(test) }
    
    context "#to_s" do
      it { string.to_s.should_not == "letest" }
    end
  end
end
