class Pet < Granite::Base
  connection pg
  table pets

  column id : Int64, primary: true
  column name : String?
  column breed : String?
  column age : Int32?
  timestamps
end
