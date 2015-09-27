class Chit

  include DataMapper::Resource

  property :id,         Serial
  property :chit_text,  String
  property :created_at, DateTime

  belongs_to :user

  validates_presence_of :chit_text

end
