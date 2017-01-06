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
  YEAR = MONTH*12

  def self.real_time(time = self.time)
    start_year, game_time = get([:StartYear, :GameTime])
    game_time = game_time.to_i

    Time.utc(start_year.to_i).advance(
      months: game_time / MONTH,
      seconds: game_time % MONTH,
    )
  end

  def self.time
    get(:GameTime).to_f
  end

  def self.last_time
    get(:PreviousGameTime).to_f
  end
end

class SystemBody < Sequel::Model
  set_dataset DB[:SystemBody].where(GameID: GAME_ID)
  set_primary_key :SystemBodyID

  def name
    self[:Name]
  end
end

class SystemBodyName < Sequel::Model
  set_dataset DB[:SystemBodyName]
  set_primary_key :SystemBodyNameID
end

class Population < Sequel::Model
  set_dataset DB[:Population].where(GameID: GAME_ID, RaceID: RACE_IDS)
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

  def system_body_name
    if name = SystemBodyName.where(RaceID: self[:RaceID], SystemBodyID: self[:SystemBodyID]).get(:Name)
      return name
    else
      return SystemBody.where(SystemBodyID: self[:SystemBodyID]).get(:Name)
    end
  end
  alias_method :name, :system_body_name

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

  def population
    self[:Population].to_f * 1_000_000
  end
end

class Commander < Sequel::Model
  set_dataset DB[:Commander].where(GameID: GAME_ID, RaceID: RACE_IDS)
  set_primary_key :CommanderID

  START_AGE = 21

  def CommandID
    self[:CommandID]
  end

  def name
    self[:Name]
  end

  def years_old
    (Game.time - self[:CareerStart]) / Game::YEAR + START_AGE
  end

  def health_risk
    # http://aurora2.pentarch.org/index.php?topic=841.0
    risk = self[:HealthRisk].to_f
    if (age = self.years_old) > 61.0
      risk += (years_old - 60)/2
    end
    return risk
  end
end

class Governor < Commander
  set_dataset Commander.where(CommandType: [3, 4])

  many_to_one :population, key: :CommandID

  def governed_body
    population.system_body
  end

  def full_title
    "Governor #{name} of #{governed_body.name}"
  end
end

class Researcher < Commander
  set_dataset Commander.where(CommandType: 7)

  def field
    ResearchField.by_id(self[:ResSpecID])
  end

  def full_title
    "Researcher #{name} (#{field.abbreviation})"
  end
end

class ResearchField < Sequel::Model
  # Memoized because it never changes.
  def self.by_id(id)
    @fields_by_id ||= map_fields_by_id
    @fields_by_id.fetch(id)
  end

  def self.map_fields_by_id
    all.map do |field|
      [field[:ResearchFieldID], field]
    end.to_h
  end

  def abbreviation
    self[:Abbreviation]
  end
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

class GameLog < Sequel::Model
  set_dataset DB[:GameLog].where(GameID: GAME_ID, RaceID: RACE_IDS)
  set_primary_key :GameLogID

  def text
    self[:MessageText]
  end

  def time
    self[:Time]
  end
end
