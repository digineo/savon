require "spec_helper"

describe Hash do

  describe "find_soap_body" do
    it "should return the content from the 'soap:Body' element" do
      soap_body = { "soap:Envelope" => { "soap:Body" => "content" } }
      soap_body.find_soap_body.should == "content"
    end

    it "should return an empty Hash in case the 'soap:Body' element could not be found" do
      soap_body = { "some_hash" => "content" }
      soap_body.find_soap_body.should == {}
    end
  end

  describe "to_soap_xml" do
    describe "should return SOAP request compatible XML" do
      it "for a simple Hash" do
        hash, result = { :some => "user" }, "<wsdl:some>user</wsdl:some>"
        hash.to_soap_xml.should == result
      end

      it "for a nested Hash" do
        hash, result = { :some => { :new => "user" } }, "<wsdl:some><wsdl:new>user</wsdl:new></wsdl:some>"
        hash.to_soap_xml.should == result
      end

      it "for a Hash with multiple keys" do
        hash = { :all => "users", :before => "whatever" }
        hash.to_soap_xml.should include("<wsdl:all>users</wsdl:all>", "<wsdl:before>whatever</wsdl:before>")
      end

      it "for a Hash containing an Array" do
        hash, result = { :some => ["user", "gorilla"] }, "<wsdl:some>user</wsdl:some><wsdl:some>gorilla</wsdl:some>"
        hash.to_soap_xml.should == result
      end

      it "for a Hash containing an Array of Hashes" do
        hash = { :some => [{ :new => "user" }, { :old => "gorilla" }] }
        result = "<wsdl:some><wsdl:new>user</wsdl:new></wsdl:some><wsdl:some><wsdl:old>gorilla</wsdl:old></wsdl:some>"

        hash.to_soap_xml.should == result
      end
    end

    it "should convert Hash key Symbols to lowerCamelCase" do
      hash, result = { :find_or_create => "user" }, "<wsdl:findOrCreate>user</wsdl:findOrCreate>"
      hash.to_soap_xml.should == result
    end

    it "should not convert Hash key Strings" do
      hash, result = { "find_or_create" => "user" }, "<wsdl:find_or_create>user</wsdl:find_or_create>"
      hash.to_soap_xml.should == result
    end

    it "should convert DateTime objects to xs:dateTime compliant Strings" do
      hash = { :before => DateTime.new(2012, 03, 22, 16, 22, 33) }
      result = "<wsdl:before>2012-03-22T16:22:33Z</wsdl:before>"

      hash.to_soap_xml.should == result
    end

    it "should convert Objects responding to to_datetime to xs:dateTime compliant Strings" do
      singleton = Object.new
      def singleton.to_datetime
        DateTime.new(2012, 03, 22, 16, 22, 33)
      end

      hash, result = { :before => singleton }, "<wsdl:before>2012-03-22T16:22:33Z</wsdl:before>"
      hash.to_soap_xml.should == result
    end

    it "should call to_s on Strings even if they respond to to_datetime" do
      object = "gorilla"
      object.expects(:to_datetime).never

      hash, result = { :name => object }, "<wsdl:name>gorilla</wsdl:name>"
      hash.to_soap_xml.should == result
    end

    it "should call to_s on any other Object" do
      [666, true, false].each do |object|
        { :some => object }.to_soap_xml.should == "<wsdl:some>#{object}</wsdl:some>"
      end

      { :some => nil }.to_soap_xml.should == "<wsdl:some xsi:nil=\"true\"/>"
    end

    it "should default to escape special characters" do
      result = { :some => { :nested => "<tag />" }, :tag => "<tag />" }.to_soap_xml
      result.should include("<wsdl:tag>&lt;tag /&gt;</wsdl:tag>")
      result.should include("<wsdl:some><wsdl:nested>&lt;tag /&gt;</wsdl:nested></wsdl:some>")
    end

    it "should not escape special characters for keys marked with an exclamation mark" do
      result = { :some => { :nested! => "<tag />" }, :tag! => "<tag />" }.to_soap_xml
      result.should include("<wsdl:tag><tag /></wsdl:tag>")
      result.should include("<wsdl:some><wsdl:nested><tag /></wsdl:nested></wsdl:some>")
    end

    it "should preserve the order of Hash keys and values specified through :order!" do
      hash = { :find_user => { :name => "Lucy", :id => 666, :order! => [:id, :name] } }
      result = "<wsdl:findUser><wsdl:id>666</wsdl:id><wsdl:name>Lucy</wsdl:name></wsdl:findUser>"
      hash.to_soap_xml.should == result

      hash = { :find_user => { :mname => "in the", :lname => "Sky", :fname => "Lucy", :order! => [:fname, :mname, :lname] } }
      result = "<wsdl:findUser><wsdl:fname>Lucy</wsdl:fname><wsdl:mname>in the</wsdl:mname><wsdl:lname>Sky</wsdl:lname></wsdl:findUser>"
      hash.to_soap_xml.should == result
    end

    it "should raise an error if the :order! Array does not match the Hash keys" do
      hash = { :name => "Lucy", :id => 666, :order! => [:name] }
      lambda { hash.to_soap_xml }.should raise_error(ArgumentError)

      hash = { :by_name => { :name => "Lucy", :lname => "Sky", :order! => [:mname, :name] } }
      lambda { hash.to_soap_xml }.should raise_error(ArgumentError)
    end

    it "should add attributes to Hash keys specified through :attributes!" do
      hash = { :find_user => { :person => "Lucy", :attributes! => { :person => { :id => 666 } } } }
      result = '<wsdl:findUser><wsdl:person id="666">Lucy</wsdl:person></wsdl:findUser>'
      hash.to_soap_xml.should == result

      hash = { :find_user => { :person => "Lucy", :attributes! => { :person => { :id => 666, :city => "Hamburg" } } } }
      soap_xml = hash.to_soap_xml
      soap_xml.should include('id="666"', 'city="Hamburg"')
    end

    it "should add attributes to duplicate Hash keys specified through :attributes!" do
      hash = { :find_user => { :person => ["Lucy", "Anna"], :attributes! => { :person => { :id => [1, 3] } } } }
      result = '<wsdl:findUser><wsdl:person id="1">Lucy</wsdl:person><wsdl:person id="3">Anna</wsdl:person></wsdl:findUser>'
      hash.to_soap_xml.should == result
      
      hash = { :find_user => { :person => ["Lucy", "Anna"], :attributes! => { :person => { :active => "true" } } } }
      result = '<wsdl:findUser><wsdl:person active="true">Lucy</wsdl:person><wsdl:person active="true">Anna</wsdl:person></wsdl:findUser>'
      hash.to_soap_xml.should == result
    end
  end

  describe "map_soap_response" do
    it "should convert Hash key Strings to snake_case Symbols" do
      soap_response = { "userResponse" => { "accountStatus" => "active" } }
      result = { :user_response => { :account_status => "active" } }

      soap_response.map_soap_response.should == result
    end

    it "should strip namespaces from Hash keys" do
      soap_response = { "ns:userResponse" => { "ns2:id" => "666" } }
      result = { :user_response => { :id => "666" } }

      soap_response.map_soap_response.should == result
    end

    it "should convert Hash keys and values in Arrays" do
      soap_response = { "response" => [{ "name" => "dude" }, { "name" => "gorilla" }] }
      result = { :response=> [{ :name => "dude" }, { :name => "gorilla" }] }

      soap_response.map_soap_response.should == result
    end

    it "should convert xsi:nil values to nil Objects" do
      soap_response = { "userResponse" => { "xsi:nil" => "true" } }
      result = { :user_response => nil }

      soap_response.map_soap_response.should == result
    end

    it "should convert Hash values matching the xs:dateTime format into DateTime Objects" do
      soap_response = { "response" => { "at" => "2012-03-22T16:22:33" } }
      result = { :response => { :at => DateTime.new(2012, 03, 22, 16, 22, 33) } }

      soap_response.map_soap_response.should == result
    end

    it "should convert Hash values matching 'true' to TrueClass" do
      soap_response = { "response" => { "active" => "false" } }
      result = { :response => { :active => false } }

      soap_response.map_soap_response.should == result
    end

    it "should convert Hash values matching 'false' to FalseClass" do
      soap_response = { "response" => { "active" => "true" } }
      result = { :response => { :active => true } }

      soap_response.map_soap_response.should == result
    end
  end

end
