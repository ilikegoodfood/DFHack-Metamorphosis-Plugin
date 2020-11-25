-- Handle sequential transformations over a race's lifespan, simulating life-stages.
-- by ilikegoodfood
local help = [====[
Metamorphosis Handler
==============
Manages life-stages, transformations and injuries for races that undergo metamorphosis throughout their lives. Suitable real-world examples include most insect.
It takes the following arguments:
-flag, -race, -unit, -historicalFigure, -scheduleYear, -sheduleTick, -script

-flag
-flag determines what the script will do and what arguments it needs. Valid flags are:

(not entering a flag at all) - runs the help command that you are seeing now.
help - runs the help command that you are seeing now.
addRace - initializes this script to include race -race and link to script command -script.
iterateUnits - iterates through all units and historical units to perform transformations.
iterateHistorical - iterates through all historical figures and performs.
schedule - takes the provided -unit, -scheduleYear and -scheduleTick and stores them. These values will then be used to call the unit later.
debug - runs the debugHelp command for the debug options.
debugHelp - runs the debugHelp command for the debug options.

-race
Valid inputs are a race\'s name, as written in the raw file (not case sensitive), or a raceID.

-unit
Valid input is unit.id.

-historicalFigure
Valid input is historicalFigure.id.

-scheduleYear
Valid inputs are integers.

-scheduleTick
Valid inputs are integers.

-script
NOT FOR MANUAL USE: Takes the string name of a lua script for storage alongside added races.
]====]

local debugHelp = [====[
Metamorphosis Handler Debug Flags
==============
Debug Flags:

debug - runs the debugHelp command that you are seeing now.
debugHelp - runs the debugHelp command that you are seeing now.

debugRemoveRace
Removes race -race from this handler.

debugReinitializeRace.
Removes race -race fromn this hanbdler, then re-initializes this script to include race -race and link to script command -script.

debugFrequencyUnits
Sets the frequency at which it iterates over units to the provided -scheduleTick. Default value of 1200 is recommended for fortress mode, 7200 for adventure mode.
Higher values are more performant, as they this script runs less often. This may lead to strange behaviours, such as children being born in the wrong caste remaining active in that caste for prolongued periods of time. This will also effect guests, invaders and merchants.
Lower values are more responsive, but are significantly less poerformant, as the script runs more often. This may lead to a loss in average frame-rate, manifesting strongly in specific ticks that corrispond to the interval of this script's operation.

debugFrequencyHistorical - sets the frequency at which it iterates over historical figures to the provided -scheduleTick. Default value of 33600 is recommended for fortress mode, 1209600 for adventure mode.
Higher values are more performant, as they this script runs less often. This may lead to strange behaviours, such as historical figures being born in the wrong caste remaining active in that caste for prolongued periods of time. This will also effect guests, invaders and merchants.
Lower values are more responsive, but are significantly less poerformant, as the script runs more often. This may lead to a loss in average frame-rate, manifesting strongly in specific ticks that corrispond to the interval of this script's operation.

]====]

local utils = require('utils')
local validArgs = utils.invert({
'flag',
'race',
'unit',
'historicalFigure',
'scheduleYear',
'scheduleTick',
'script'
})
local args = utils.processArgs({...}, validArgs)

-- --------------------------------------------------
-- Declare all local variables
-- --------------------------------------------------
races = races or {}
frequencyUnits = frequencyUnits or 1200 -- how often the script iterates over units, in ticks. 1200 = once per day, which is aproximately 34 seconds at 30fps.
frequencyHistorical = frequencyHistorical or 33600 -- how often the script iterates over historical figures. 33600 = once per month, which is aproximately 16 minutes 40 seconds at 30fps.

-- --------------------------------------------------
-- Declare all functions
-- --------------------------------------------------

-- --------------------------------------------------
-- This function will Metamorphosis the unit to the correct life stage, calling on the Metamorphosis method of that race in its own metamorphosis script.
function Metamorphosis(unit)
	print('passing unit ' .. unit.id .. ' to ' .. tostring(races[unit.race]['script']))
	if tostring(races[unit.race]['script']) == 'test' then
		print ('Test')
	else
		dfhack.run_script(tostring(races[unit.race]['script']), '-flag', 'metamorphosis', '-unit', tostring(unit.id))
	end
end

-- --------------------------------------------------
-- Taken from animal-control.lua and modified.
-- This function checks if args.race is a raceID or raceName. If a name, it finds the matching ID and assigns it to args.race.
function ValidateRace()
	if args.race then
		if not tonumber(args.race) then
			print ('Race provided is not numerical ID')
			args.race=string.upper(args.race)
			print ('Race string is ' .. args.race)
			local raceID
			for i,c in ipairs(df.global.world.raws.creatures.all) do
				if c.creature_id == args.race then
					raceID = i
					break
				end
			end
			
			if not raceID then
				qerror('Invalid race: ' .. args.race)
			end
			args.race = raceID
			print ('Numerical ID for race is ' .. args.race)
		else
			args.race = tonumber(args.race);
		end
	end
end

-- --------------------------------------------------
-- This function checks if args.unit is a unitID. If a unitID, it finds the matching unit reference and assigns it to args.unit.
function ValidateUnit()
	if args.unit and tonumber(args.unit) then
		args.unit = df.unit.find(args.unit)
	elseif not unit.id then
		qerror ('Invalid Unit: Input ' .. args.unit .. ' is not a valid unit.id or unit ref.')
	end
end

-- --------------------------------------------------
-- This function validates -race and initializes it in this handler.
function AddRace()
	if args.race and args.script then
		ValidateRace()
		
		local handshake = false
		if args.script == 'test' then
			handshake = true
		elseif dfhack.findScript(tostring(args.script)) then
			handshake = dfhack.run_script(tostring(args.script), '-flag', 'handshake')
		end
		
		if handshake then
			-- Initializes table with race key and sub tables.
			if not races[args.race] then
				races[args.race] = { ['script'] = args.script, ['unitAge'] = {}, ['targetAge'] = {} }
				-- Implement handshake protocall.
				print ('New race ' .. args.race .. ' has been initialized for handling.')
			elseif races[args.race] and races[args.race]['script'] ~= args.script then
				qerror ('Race ' .. args.race .. ' has already been initialized by a different script. Only one script may hanlde any given race. If you meant to replace the currently registered script, use -flag debugReinitializeRace.')
			else
				print ('Race ' .. args.race .. ' has already been initialized.')
			end
			
			local int = NumberOfKeys(races)
			if int == 1 then
				print ('A total of ' .. int .. ' race has been initialized by this handler.')
			else
				print ('A total of ' .. int .. ' races have been initialized by this handler.')
			end
		else
			qerror ('Handshake failed to verify -script ' .. tostring(args.script) .. '. Please ensure that the script name provided exactly matches the script file name, excluding file extension, and that its \'handshake Branch\' returns true')
		end
	end
end

-- --------------------------------------------------
-- This function validates -race and removes it from this handler.
function RemoveRace()
	if args.race then
		ValidateRace()

		-- Removes value for proivided race from table.
		if races[args.race]==nil then
			print ('Race ' .. args.race .. ' has not been initialized by this handler')
		else
			races[args.race] = nil
			print ('Race ' .. args.race .. ' has been removed from this handler')
		end
		
		local int = NumberOfKeys(races)
		if int == 1 then
			print ('A total of ' .. int .. ' race has been initialized by this handler.')
		else
			print ('A total of ' .. int .. ' races have been initialized by this handler.')
		end
	else
		qerror ('debugRemoveRace requires -race arg')
	end
end

-- --------------------------------------------------
-- Provided by Atkana on the unofficial Dwarf Fortress Discord.
-- This function returns the number of entries in a table.
function NumberOfKeys(keyedTable)
  local keyNum = 0
  for key, entry in pairs(keyedTable) do
    keyNum = keyNum + 1
  end
  return keyNum
end

-- --------------------------------------------------
-- Script execution starts here
-- --------------------------------------------------
-- Prints help if no flag is entered, or if flag == help.
if not args.flag or args.flag == 'help' then
	print (help)
-- --------------------------------------------------
-- addRace Branch: Script initializes to handle provided race.
elseif args.flag == 'addRace' then
	if args.race and args.script then
		AddRace()
	else
		qerror ('addRace requires -race and -script args')
	end
-- --------------------------------------------------
-- iterateUnits Branch: Iterates over all units, documenting them and passing them on to species-specific metamorphosis script as required.
elseif args.flag == 'iterateUnits' then
	-- If there are races listed, performs all operations on each unit of those races.
	local int = NumberOfKeys(races)
	if int==0 then
		print('No races initialized')
	else
		
		if int == 1 then
			print ('Iterating units for ' .. int .. ' race...')
		else
			print ('Iterating units for ' .. int .. ' races...')
		end
		print ('current game-time is ' .. df.global.cur_year .. ' years ' .. df.global.cur_year_tick .. ' ticks.')
		
		for _, unit in ipairs(df.global.world.units.all) do
			if races[unit.race] then
				-- Set the current age of the unit in ticks.
				if not races[unit.race]['unitAge'][unit] then
					races[unit.race]['unitAge'][unit] = {}
				end
				
				races[unit.race]['unitAge'][unit]['years'] = df.global.cur_year - unit.birth_year
				races[unit.race]['unitAge'][unit]['ticks'] = df.global.cur_year_tick - unit.birth_time
				
				if races[unit.race]['unitAge'][unit]['ticks'] < 0 then
					races[unit.race]['unitAge'][unit]['ticks'] = 403200 + races[unit.race]['unitAge'][unit]['ticks']
					races[unit.race]['unitAge'][unit]['years'] = races[unit.race]['unitAge'][unit]['years'] - 1
				end
				
				print ('Unit ' .. unit.id .. ' is ' .. races[unit.race]['unitAge'][unit]['years'] .. ' years and ' .. races[unit.race]['unitAge'][unit]['ticks'] .. ' ticks old.')

				-- Set the tick upon which the next metamorphosis will take place if there is none, or metamorphosis if targetAge is less than unitAge.
				if races[unit.race]['targetAge'][unit] then
					-- If the unit is older than its next scehduled metamorphosis, it will metamorphosis. The Metamorphosis function will call the handler in the race-scpeicifc metamorphosis command.
					if races[unit.race]['targetAge'][unit]['years']~=-1 and races[unit.race]['unitAge'][unit]['years'] <= races[unit.race]['targetAge'][unit]['years'] and races[unit.race]['unitAge'][unit]['ticks'] <= races[unit.race]['targetAge'][unit]['ticks'] then
						Metamorphosis(unit)
					end
				else
					-- If the unit has not been initialized, it will metamorphosis. The Metamorphosis function will call the handler in the race-scpeicifc metamorphosis command.
					Metamorphosis(unit)
				end
			end
		end
	end
-- --------------------------------------------------
-- iterateHistorical Branch: Iterates over all historical figures, documenting them and passing them on to species-specific metamorphosis script as required.
elseif args.flag == 'iterateHistorical' then
	print ('iterateHistorical Branch: Not yet implemented')
-- --------------------------------------------------
-- schedule Branch: stores targetAge for provided unit.
elseif args.flag == 'schedule' then
	if args.unit and args.scheduleYear and tonumber (args.scheduleYear) and args.scheduleTick  and tonumber(args.scheduleTick) then
		ValidateUnit()
		
		if args.unit then
			races[args.unit.race]['targetAge'][args.unit]['years'] = tonumber(args.scheduleYear)
			races[args.unit.race]['targetAge'][args.unit]['ticks'] = tonumber(args.scheduleTick)
		end
	elseif args.historicalFigure and args.scheduleYear and tonumber (args.scheduleYear) and args.scheduleTick  and tonumber(args.scheduleTick) then
		print ('schedule Branch: Historical Figures not yet implemented.')
	else
		qerror('shedule requires -unit, -scheduleYear and -scheduleTick args')
	end
-- --------------------------------------------------
-- debug Branch: Prints debugHelp if flag == debug.
elseif args.flag == 'debug' or args.flag == 'debugHelp' then
	print (debugHelp)
-- --------------------------------------------------
-- debugFrequencyUnits Branch: Changes the frequency at which iterateUnits Branch is run.
elseif args.flag == 'debugFrequencyUnits' then
	if args.scheduleTick and tonumber(args.scheduleTick) then
		frequencyUnits = tonumber(args.scheduleTick)
		print ('iterateUnits frequency changed to ' .. frequencyUnits .. ' ticks.')
	end
-- --------------------------------------------------
-- debugFrequencyHistorical Branch: Changes the frequency at which iterateHistorical Branch is run.
elseif args.flag == 'debugFrequencyHistorical' then
	if args.scheduleTick and tonumber(args.scheduleTick) then
		frequencyHistorical = tonumber(args.scheduleTick)
		print ('iterateHistorical frequency changed to ' .. frequencyHistorical .. ' ticks.')
	end
-- --------------------------------------------------
-- debugRemoveRace Branch: Removes provided race from this handler.
elseif args.flag == 'debugRemoveRace' then
	if args.race then
		RemoveRace()
	end
-- --------------------------------------------------
-- debugReinitializeRace Branch: Removes provided race from this handler, then initializes to handle provided race.
elseif args.flag == 'debugReinitializeRace' then
	if args.race and args.script then
		RemoveRace()
		AddRace()
	else
		qerror ('debugRemoveRace requires -race and -script args')
	end
-- --------------------------------------------------
-- Invalid Flag error message.
else
	qerror ('Invalid flag ' .. args.flag .. '. Run script with no flag or with \'-flag help\' to get the flag and argument lists.')
end