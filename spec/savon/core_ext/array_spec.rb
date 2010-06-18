require "spec_helper"

describe Array do

  describe "to_soap_xml" do
    it "should return the XML for an Array of Hashes" do
      array = [{ :name => "adam" }, { :name => "eve" }]
      result = "<wsdl:user><wsdl:name>adam</wsdl:name></wsdl:user><wsdl:user><wsdl:name>eve</wsdl:name></wsdl:user>"
      
      array.to_soap_xml("user").should == result
    end

    it "should return the XML for an Array of different Objects" do
      array = [:symbol, "string", 123]
      result = "<wsdl:value>symbol</wsdl:value><wsdl:value>string</wsdl:value><wsdl:value>123</wsdl:value>"
      
      array.to_soap_xml("value").should == result
    end

    it "should default to escape special characters" do
      array = ["<tag />", "adam & eve"]
      result = "<wsdl:value>&lt;tag /&gt;</wsdl:value><wsdl:value>adam &amp; eve</wsdl:value>"
      
      array.to_soap_xml("value").should == result
    end

    it "should not escape special characters when told to" do
      array = ["<tag />", "adam & eve"]
      result = "<wsdl:value><tag /></wsdl:value><wsdl:value>adam & eve</wsdl:value>"
      
      array.to_soap_xml("value", false).should == result
    end

    it "should add attributes to a given tag" do
      array = ["adam", "eve"]
      result = '<wsdl:value active="true">adam</wsdl:value><wsdl:value active="true">eve</wsdl:value>'
      
      array.to_soap_xml("value", :escape_xml, :active => true).should == result
    end

    it "should add attributes to duplicate tags" do
      array = ["adam", "eve"]
      result = '<wsdl:value id="1">adam</wsdl:value><wsdl:value id="2">eve</wsdl:value>'
      
      array.to_soap_xml("value", :escape_xml, :id => [1, 2]).should == result
    end
  end

end
