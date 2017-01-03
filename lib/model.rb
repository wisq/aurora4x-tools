require 'lib/access'
require 'active_support/core_ext/time'

DB = Sequel.odbc('aurora', db_type: 'access')

GAME_ID = DB[:Game].max(:GameID)
RACE_IDS = DB[:Race].where(GameID: GAME_ID, NPR: false).map { |r| r[:RaceID] }

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
  one_to_many :governors, key: :CommandID

  def PopulationID
    self[:PopulationID]
  end
  alias_method :id, :PopulationID

  def system_body_id
    self[:SystemBodyID]
  end

  def total_labs
    self[:ResearchLabs].to_f
  end

  def used_labs
    pop_id = self[:PopulationID]
    ResearchProject.where(PopulationID: id).sum(:facilities).to_f
  end

  def has_industry?
    self[:ConstructionFactories].to_f > 0.0 ||
      self[:ConventionalFactories].to_f > 0.0
  end

  def has_mines?
    self[:Mines].to_f > 0.0 ||
      self[:RemoteMines].to_f > 0.0 ||
      self[:CivilianMiningComplex] > 0
  end

  def has_mass_drivers?
    self[:MassDriver].to_f > 0.0
  end

  def has_mass_driver_target?
    self[:MassDriverDest] != 0
  end

  def has_minerals?
    MineralDeposit.where(SystemBodyID: self[:SystemBodyID]).count > 0
  end

  def used_industry
    IndustrialProject.where(PopulationID: id, Queue: 0, Pause: false).sum(:Percentage).to_f
  end

  def governor
    governors.first
  end
end

class Governor < Sequel::Model
  set_dataset DB[:Commander].where(GameID: GAME_ID, CommandType: [3, 4])
  set_primary_key :CommanderID
end

class ResearchProject < Sequel::Model
  set_dataset DB[:ResearchProject]
  set_primary_key :ProjectID
end

class IndustrialProject < Sequel::Model
  set_dataset DB[:IndustrialProjects].where(GameID: GAME_ID)
  set_primary_key :ProjectID
end

class SectorCommand < Sequel::Model
  set_dataset DB[:SectorCommand].where(RaceID: RACE_IDS)
  set_primary_key :SectorCommandID

  one_to_many :governors, key: :CommandID

  def SectorCommandID
    self[:SectorCommandID]
  end

  def name
    self[:SectorName]
  end

  def governor
    governors.first
  end
end

class MineralDeposit < Sequel::Model
  set_dataset DB[:MineralDeposit]
  set_primary_key :MineralDepositID
end
