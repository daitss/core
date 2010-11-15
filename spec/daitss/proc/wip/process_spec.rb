require 'spec_helper'
require 'daitss/proc/wip'

describe Wip do

  let(:wip) do
    w = submit 'haskell-nums-pdf'

    def w.snooze
      sleep
    end

    w.info[:task] = :snooze
    w.save_info
    w
  end

  before(:each) do
    wip.kill 'KILL' if wip.running?
    sleep 0.1 while wip.running?
    wip.reset_process
  end

  it "should spawn and kill" do
    wip.should_not be_running
    wip.spawn
    wip.should be_running
    wip.kill
    wip.should_not be_running
  end

  it 'should be idle to spawn' do
    wip.spawn
    wip.should be_running
    lambda { wip.spawn }.should raise_error('idle state is required, not running')
  end

  it 'should be dead if killed by something foreign' do
    wip.spawn
    wip.should be_running
    Process.kill "KILL", wip.process[:id] rescue nil
    sleep 0.1 while wip.running?
    wip.should be_dead
  end

  it 'should be stoppable and unstoppable' do
    wip.spawn
    wip.should be_running
    wip.stop
    wip.should_not be_running
    wip.should be_stopped
    wip.unstop
    lambda { wip.spawn }.should_not raise_error
  end

  it 'should be stopped to unstop' do
    wip.should_not be_stopped
    lambda { wip.unstop }.should raise_error('stop state is required, not idle')
  end

  it 'should be snafu on raised errors' do

    def wip.blow_up
      puts 'about to blow up'
      raise 'something went really wrong'
    end

    wip.info[:task] = :blow_up
    wip.save_info

    wip.spawn
    sleep 0.1 while wip.running?
    wip.should be_snafu

    wip.unsnafu
    wip.should_not be_snafu
  end

  it 'should be snafu to unsnafu' do
    wip.should_not be_snafu
    lambda { wip.unsnafu }.should raise_error('snafu state is required, not idle')
  end

end
