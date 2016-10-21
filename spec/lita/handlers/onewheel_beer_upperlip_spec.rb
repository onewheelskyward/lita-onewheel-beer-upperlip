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
    expect(replies.last).to eq("Bailey's upperlip: 1) Cider Riot! Plastic Paddy  2) Fox Tail Rosenberry  3) (Cask) Machine House Crystal Maze  4) Wild Ride Solidarity  5) Mazama Gillian’s Red  6) (Nitro) Backwoods Winchester Brown  7) Fort George Vortex  8) Fat Head’s Zeus Juice  9) Hopworks Noggin’ Floggin’  10) Anderson Valley Briney Melon Gose  11) Lagunitas Copper Fusion Ale  12) Double Mountain Fast Lane  13) Burnside Couch Lager  14) Bell’s Oatmeal Stout  15) Baerlic Wildcat  16) New Belgium La Folie  17) Culmination Urizen  18) Knee Deep Hop Surplus  19) Cascade Lakes Ziggy Stardust  20) Knee Deep Dark Horse  21) Coronado Orange Avenue Wit  22) GoodLife 29er  23) Amnesia Slow Train Porter  24) Oakshire Perfect Storm  25) Green Flash Passion Fruit Kicker")
  end

  it 'displays details for tap 4' do
    send_command 'upperlip 4'
    expect(replies.last).to eq('Bailey\'s tap 4) Wild Ride Solidarity - Abbey Dubbel – Barrel Aged (Pinot Noir) 8.2%, 4oz - $4 | 12oz - $7, 26% remaining')
  end

  it 'searches for ipa' do
    send_command 'upperlip ipa'
    expect(replies.last).to eq("Bailey's tap 24) Oakshire Perfect Storm - Imperial IPA 9.0%, 10oz - $4 | 20oz - $6 | 32oz Crowler - $10, 61% remaining")
  end
end
