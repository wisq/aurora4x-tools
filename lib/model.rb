require 'lib/access'
require 'active_support/core_ext/time'

DB = Sequel.odbc('aurora', db_type: 'access')

GAME_ID = DB[:Game].max(:GameID)

class Game < Sequel::Model
  set_dataset DB[:Game].where(GameID: GAME_ID)
  set_primary_key :GameID

  DAY = 86400
  MONTH = DAY*30

  def self.time
    start_year, game_time = get([:StartYear, :GameTime])
    game_time = game_time.to_i

    Time.utc(start_year.to_i).advance(
      months: game_time / MONTH,
      seconds: game_time % MONTH,
    )
  end
end

class SystemBody < Sequel::Model
  set_dataset DB[:SystemBody].where(GameID: GAME_ID)
  set_primary_key :SystemBodyID

  def name
    self[:Name]
  end
end

class Population < Sequel::Model
  set_dataset DB[:Population].where(GameID: GAME_ID)
  set_primary_key :PopulationID

  many_to_one :system_body, key: :system_body_id
  one_to_many :governor, key: :CommandID

  def PopulationID
    self[:PopulationID]
  end

  def system_body_id
    self[:SystemBodyID]
  end

  def total_labs
    self[:ResearchLabs].to_f
  end

  def used_labs
    pop_id = self[:PopulationID]
    ResearchProject.where(PopulationID: pop_id).sum(:facilities).to_f
  end
end

class Governor < Sequel::Model
  set_dataset DB[:Commander].where(GameID: GAME_ID, CommandType: 3)
  set_primary_key :CommanderID
end

class ResearchProject < Sequel::Model
  set_dataset DB[:ResearchProject]
  set_primary_key :ProjectID
end
