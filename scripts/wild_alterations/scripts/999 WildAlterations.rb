# Wild Alterations
#
# Author : Raty
# License : MIT
#
# A PSDK plugin that can inflict status conditions
# and modify the HP of wild creatures.
#
# Documentation :
# https://github.com/RatyHub/Wild-Alterations

module Configs
  KEY_TRANSLATIONS[:alterationChance] = :alteration_chance
  KEY_TRANSLATIONS[:alterationTypes] = :alteration_types
  KEY_TRANSLATIONS[:applyTo] = :apply_to

  module Project
    class WildAlterations
      class WeightedEntry
        attr_reader :name
        attr_reader :weight

        def initialize(value = {})
          value = {} unless value.is_a?(Hash)
          @name = value[:name] || value['name']
          @name = @name.to_sym if @name
          @weight = (value[:weight] || value['weight'] || 0).to_f
        end

        def to_h
          { name: name, weight: weight }
        end
      end

      class Hp
        attr_reader :loss_percent_range

        def initialize(value = {})
          value = {} unless value.is_a?(Hash)
          self.loss_percent_range = value[:loss_percent_range] || value[:lossPercentRange] || value['loss_percent_range'] || value['lossPercentRange'] || [5, 10]
        end

        def loss_percent_range=(value)
          values = Array(value).map(&:to_i)
          min = values[0] || 0
          max = values[1] || min
          min, max = max, min if min > max
          @loss_percent_range = min..max
        end

        def to_h
          { lossPercentRange: [loss_percent_range.begin, loss_percent_range.end] }
        end
      end

      class ApplyTo
        attr_accessor :forced_battles
        attr_accessor :boss
        attr_accessor :roaming
        attr_accessor :fishing
        attr_accessor :safari

        def initialize(value = {})
          value = {} unless value.is_a?(Hash)
          @forced_battles = read_bool(value, :forced_battles, :forcedBattles, false)
          @boss = read_bool(value, :boss, :boss, false)
          @roaming = read_bool(value, :roaming, :roaming, false)
          @fishing = read_bool(value, :fishing, :fishing, true)
          @safari = read_bool(value, :safari, :safari, true)
        end

        def to_h
          {
            forcedBattles: forced_battles,
            boss: boss,
            roaming: roaming,
            fishing: fishing,
            safari: safari
          }
        end

        private

        def read_bool(hash, snake_key, camel_key, default)
          return hash[snake_key] unless hash[snake_key].nil?
          return hash[camel_key] unless hash[camel_key].nil?
          return hash[snake_key.to_s] unless hash[snake_key.to_s].nil?
          return hash[camel_key.to_s] unless hash[camel_key.to_s].nil?

          return default
        end
      end

      class Exclude
        attr_reader :species
        attr_reader :maps

        def initialize(value = {})
          value = {} unless value.is_a?(Hash)
          self.species = value[:species] || value['species'] || []
          self.maps = value[:maps] || value['maps'] || []
        end

        def species=(value)
          @species = Array(value).filter_map { |db_symbol| normalize_db_symbol(db_symbol) }
        end

        def maps=(value)
          @maps = Array(value).map(&:to_i)
        end

        def to_h
          {
            species: species.map { |db_symbol| ":#{db_symbol}" },
            maps: maps
          }
        end

        private

        def normalize_db_symbol(value)
          db_symbol = value.to_s.strip
          db_symbol = db_symbol[1..] if db_symbol.start_with?(':')
          db_symbol = db_symbol.downcase
          return nil if db_symbol.empty?

          return db_symbol.to_sym
        end
      end

      attr_accessor :enabled
      attr_accessor :logs
      attr_reader :alteration_chance
      attr_reader :alteration_types
      attr_reader :status
      attr_reader :hp
      attr_reader :apply_to
      attr_reader :exclude

      def initialize
        @enabled = true
        @logs = false
        @alteration_chance = 15
        @alteration_types = [WeightedEntry.new(name: :status, weight: 20), WeightedEntry.new(name: :hp, weight: 80)]
        @status = [
          WeightedEntry.new(name: :poison, weight: 40),
          WeightedEntry.new(name: :paralysis, weight: 40),
          WeightedEntry.new(name: :sleep, weight: 20)
        ]
        @hp = Hp.new(lossPercentRange: [5, 10])
        @apply_to = ApplyTo.new
        @exclude = Exclude.new
      end

      def alteration_chance=(value)
        @alteration_chance = value.to_f.clamp(0, 100)
      end

      def alteration_types=(value)
        @alteration_types = weighted_entries(value)
      end

      def status=(value)
        @status = weighted_entries(value)
      end

      def hp=(value)
        @hp = value.is_a?(Hp) ? value : Hp.new(value)
      end

      def apply_to=(value)
        @apply_to = value.is_a?(ApplyTo) ? value : ApplyTo.new(value)
      end

      def exclude=(value)
        @exclude = value.is_a?(Exclude) ? value : Exclude.new(value)
      end

      def to_json(*args)
        {
          enabled: enabled,
          logs: logs,
          alterationChance: alteration_chance,
          alterationTypes: alteration_types.map(&:to_h),
          status: status.map(&:to_h),
          hp: hp.to_h,
          applyTo: apply_to.to_h,
          exclude: exclude.to_h
        }.to_json(*args)
      end

      private

      def weighted_entries(value)
        Array(value).map { |entry| entry.is_a?(WeightedEntry) ? entry : WeightedEntry.new(entry) }.select { |entry| entry.name && entry.weight.positive? }
      end
    end
  end

  # @!method self.wild_alterations
  # @return [Configs::Project::WildAlterations]
  register(:wild_alterations, File.join('plugins', 'wild_alterations_config'), :json, false, Project::WildAlterations)
end

module WildAlterations
  module_function

  def config
    Configs.wild_alterations
  end

  def enabled?
    config.enabled
  end

  def logs?
    config.logs
  end

  def log(message)
    return unless logs?

    log_info(message)
  end

  def roll_percent(chance)
    rand(100) < chance.to_f.clamp(0, 100)
  end

  def pick_weighted(entries)
    entries = Array(entries).select { |entry| entry.weight.positive? }
    total_weight = entries.reduce(0) { |sum, entry| sum + entry.weight }
    return nil if total_weight <= 0

    roll = rand * total_weight
    entries.each do |entry|
      roll -= entry.weight
      return entry.name if roll < 0
    end

    return entries.last&.name
  end
end

module PFM
  class Wild_Battle
    module WildAlterationsPatch
      private

      def configure_battle(enemy_array, battle_id)
        apply_wild_alterations(enemy_array) if apply_wild_alterations_to_battle?(enemy_array, battle_id)
        super
      end

      def apply_wild_alterations_to_battle?(enemy_array, battle_id)
        return false unless WildAlterations.enabled?
        unless enemy_array.is_a?(Array) && !enemy_array.empty?
          WildAlterations.log("skip battle_id=#{battle_id}: no enemies")
          return false
        end

        if wild_alterations_excluded_map?
          WildAlterations.log("skip battle_id=#{battle_id}: excluded map #{wild_alterations_current_map_id}")
          return false
        end

        if @forced_wild_battle && !wild_alterations_apply_to.forced_battles
          WildAlterations.log("skip battle_id=#{battle_id}: forced battle")
          return false
        end

        if wild_alterations_fishing_battle? && !wild_alterations_apply_to.fishing
          WildAlterations.log("skip battle_id=#{battle_id}: fishing battle")
          return false
        end

        if wild_alterations_safari_battle? && !wild_alterations_apply_to.safari
          WildAlterations.log("skip battle_id=#{battle_id}: safari battle")
          return false
        end

        if !wild_alterations_apply_to.boss && (boss = enemy_array.find { |pokemon| wild_alteration_boss?(pokemon) })
          WildAlterations.log("skip battle_id=#{battle_id}: boss #{wild_alteration_pokemon_label(boss)}")
          return false
        end

        if !wild_alterations_apply_to.roaming && (roaming = enemy_array.find { |pokemon| roaming?(pokemon) })
          WildAlterations.log("skip battle_id=#{battle_id}: roaming #{wild_alteration_pokemon_label(roaming)}")
          return false
        end

        return true
      end

      def wild_alterations_apply_to
        WildAlterations.config.apply_to
      end

      def wild_alterations_exclude
        WildAlterations.config.exclude
      end

      def wild_alterations_current_map_id
        return nil unless defined?($game_map) && $game_map

        return $game_map.map_id
      end

      def wild_alterations_excluded_map?
        map_id = wild_alterations_current_map_id
        return false unless map_id

        wild_alterations_exclude.maps.include?(map_id)
      end

      def wild_alterations_excluded_species?(pokemon)
        return false unless pokemon&.respond_to?(:db_symbol)

        wild_alterations_exclude.species.include?(pokemon.db_symbol)
      end

      def wild_alterations_fishing_battle?
        return true unless @fish_battle.nil?
        return false if @forced_wild_battle
        return false unless respond_to?(:current_selected_group, true)

        group = current_selected_group
        return false unless group&.respond_to?(:tool)

        FISHING_TOOLS.include?(group.tool)
      end

      def wild_alterations_safari_battle?
        return false unless defined?(Yuki::Var::BT_Mode)

        $game_variables[Yuki::Var::BT_Mode] == 5
      end

      def wild_alteration_boss?(pokemon)
        return true if pokemon.respond_to?(:boss?) && pokemon.boss?
        return true if pokemon.respond_to?(:boss) && pokemon.boss

        return false
      end

      def apply_wild_alterations(enemy_array)
        enemy_array.each do |pokemon|
          if wild_alterations_excluded_species?(pokemon)
            WildAlterations.log("#{wild_alteration_pokemon_label(pokemon)} skip: excluded species")
            next
          end

          apply_wild_alteration_roll(pokemon)
        end
      end

      def apply_wild_alteration_roll(pokemon)
        chance = WildAlterations.config.alteration_chance
        unless WildAlterations.roll_percent(chance)
          WildAlterations.log("#{wild_alteration_pokemon_label(pokemon)} roll FAIL (#{chance}%)")
          return false
        end

        WildAlterations.log("#{wild_alteration_pokemon_label(pokemon)} roll SUCCESS (#{chance}%)")
        result = apply_wild_alteration(pokemon)
        WildAlterations.log("#{wild_alteration_pokemon_label(pokemon)} result #{result ? 'SUCCESS' : 'FAIL'}")
        return result
      end

      def apply_wild_alteration(pokemon)
        alteration_type = WildAlterations.pick_weighted(WildAlterations.config.alteration_types)
        WildAlterations.log("#{wild_alteration_pokemon_label(pokemon)} type=#{alteration_type || 'none'}")

        case alteration_type
        when :status
          return true if apply_wild_status_alteration(pokemon)

          WildAlterations.log("#{wild_alteration_pokemon_label(pokemon)} fallback=hp")
          return apply_wild_hp_loss(pokemon)
        when :hp
          return true if apply_wild_hp_loss(pokemon)

          WildAlterations.log("#{wild_alteration_pokemon_label(pokemon)} fallback=status")
          return apply_wild_status_alteration(pokemon)
        end

        return false
      end

      def apply_wild_status_alteration(pokemon)
        WildAlterations.log("#{wild_alteration_pokemon_label(pokemon)} apply status alteration")
        attempted_statuses = []

        loop do
          remaining_statuses = WildAlterations.config.status.reject { |entry| attempted_statuses.include?(entry.name) }
          status = WildAlterations.pick_weighted(remaining_statuses)
          break unless status

          attempted_statuses << status
          return true if apply_wild_status(pokemon, status)
        end

        WildAlterations.log("#{wild_alteration_pokemon_label(pokemon)} status FAIL")
        return false
      end

      def apply_wild_status(pokemon, status)
        unless wild_status_applicable?(pokemon, status)
          WildAlterations.log("#{wild_alteration_pokemon_label(pokemon)} #{status} not applicable")
          return false
        end

        success = case status
                  when :poison
                    pokemon.status_poison(false)
                  when :toxic
                    pokemon.status_toxic(false)
                  when :paralysis
                    pokemon.status_paralyze(false)
                  when :burn
                    pokemon.status_burn(false)
                  when :sleep
                    pokemon.status_sleep(false)
                  when :freeze
                    pokemon.status_frozen(false)
                  end
        WildAlterations.log("#{wild_alteration_pokemon_label(pokemon)} status=#{status} #{success ? 'SUCCESS' : 'FAIL'}")
        return success
      end

      def wild_status_applicable?(pokemon, status)
        case status
        when :poison, :toxic
          return pokemon.can_be_poisoned?
        when :paralysis
          return pokemon.can_be_paralyzed?
        when :burn
          return pokemon.can_be_burn?
        when :sleep
          return pokemon.can_be_asleep?
        when :freeze
          return pokemon.can_be_frozen?(6)
        end

        WildAlterations.log("#{wild_alteration_pokemon_label(pokemon)} unknown status=#{status}")
        return false
      end

      def apply_wild_hp_loss(pokemon)
        WildAlterations.log("#{wild_alteration_pokemon_label(pokemon)} apply hp alteration")
        if pokemon.max_hp <= 1
          WildAlterations.log("#{wild_alteration_pokemon_label(pokemon)} hp FAIL max_hp=#{pokemon.max_hp}")
          return false
        end

        range = WildAlterations.config.hp.loss_percent_range
        hp_loss_percent = rand(range).to_i.clamp(0, 100)
        if hp_loss_percent <= 0
          WildAlterations.log("#{wild_alteration_pokemon_label(pokemon)} hp FAIL percent=#{hp_loss_percent}")
          return false
        end

        old_hp = pokemon.hp
        hp_loss = (pokemon.max_hp * hp_loss_percent / 100.0).floor.clamp(1, pokemon.max_hp - 1)
        pokemon.hp = pokemon.max_hp - hp_loss
        WildAlterations.log("#{wild_alteration_pokemon_label(pokemon)} hp SUCCESS -#{hp_loss} (#{hp_loss_percent}%), #{old_hp}/#{pokemon.max_hp} -> #{pokemon.hp}/#{pokemon.max_hp}")
        return true
      end

      def wild_alteration_pokemon_label(pokemon)
        return 'unknown Pokemon' unless pokemon

        name = pokemon.respond_to?(:given_name) ? pokemon.given_name : nil
        symbol = pokemon.respond_to?(:db_symbol) ? pokemon.db_symbol : pokemon.id
        level = pokemon.respond_to?(:level) ? pokemon.level : '?'
        return "#{name || symbol} (#{symbol}, lv#{level})"
      end
    end

    prepend WildAlterationsPatch unless ancestors.include?(WildAlterationsPatch)
  end
end
