class Setting

  include DataMapper::Resource

  property :id, String, :key => true
  property :value, String

  def Setting.set name, value
    Setting.create(:name => name, :value => value)
  end

end
