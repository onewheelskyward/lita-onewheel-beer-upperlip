require 'spec_helper'

describe Lita::Handlers::OnewheelBeerUpperlip, lita_handler: true do
  it { is_expected.to route_command('upperlip') }
  it { is_expected.to route_command('upperlip 4') }
  it { is_expected.to route_command('upperlip nitro') }
  it { is_expected.to route_command('upperlip CASK') }

  before do
    mock = File.open('spec/fixtures/upperlip.html').read
    allow(RestClient).to receive(:get) { mock }
  end

  it 'shows the upperlip' do
    send_command 'upperlip'
    expect(replies.last).to eq("Bailey's Upperlip tap: 1) Block 15 Bloktoberfest  2) El Segundo Wet Hop Simcoe  3) Block 15 Sticky Hands  4) <i>Available in bottles!</i> New World Cuvee  5)  Broadacres Strawberry  6) Bosteels Pauwel Kwak")
  end

  it 'displays details for tap 4' do
    send_command 'upperlip 4'
    expect(replies.last).to eq("Bailey's Upperlip tap 4) <i>Available in bottles!</i> New World Cuvee - Dry Hopped Saison 6.3%, 76% remaining")
  end

  it 'searches for ipa' do
    send_command 'upperlip ipa'
    expect(replies.last).to eq("Bailey's Upperlip tap 3) Block 15 Sticky Hands - Imperial IPA 8.1%, 73% remaining")
  end
end
