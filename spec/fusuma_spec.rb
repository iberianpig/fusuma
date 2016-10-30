require "spec_helper"

describe Fusuma do
  it "has a version number" do
    expect(Fusuma::VERSION).not_to be nil
  end

  it "#run" do
    expect(Fusuma).to receive :read_libinput
    Fusuma.run
  end
end
