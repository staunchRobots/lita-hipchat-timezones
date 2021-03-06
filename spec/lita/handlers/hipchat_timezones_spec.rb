require "spec_helper"

describe Lita::Handlers::HipchatTimezones, lita_handler: true do

  describe "#tz" do
    
    context "with @mention_name" do
      let(:name) { "@LeonardoBighetti" }
      let(:json) { { "timezone" => "America/Sao_Paulo"} }
      let(:response) do
        double("HTTParty::Response")
      end

      before do
        allow(response).to receive(:parsed_response).and_return(json)
        allow(HTTParty).to receive(:get).and_return(response)
      end

      it "replies with the user' timezone" do
        send_command("tz #{name}")
        expect(replies.last).to include "GMT-3"
      end
    end
  end
end
