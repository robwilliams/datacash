require 'spec_helper'

describe Datacash::Request::Cv2Avs do

  describe "#to_xml" do
    subject { MultiXml.parse(described_class.new.to_xml) }

    it "should have a root element of 'Cv2Avs'" do
      expect(subject).to have_key('Cv2Avs')
    end
  end
end
