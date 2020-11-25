-- Race-specific metamorphosis script for testing and developement purposes. Converts Dwarfs into Elfs at ~100 years of age.
-- template by ilikegoodfood, race-script by ilikegoodfood
local help = [====[
Metamorphosis Dwarf
==============
Handles Transformations for Dwarf race.
It takes the following arguments:
-flag, -unit

-flag
-flag determines what the script will do and what arguments it needs. Valid flags are:

(not entering a flag at all) - runs the help command that you are seeing now.
help - runs the help command that you are seeing now.
register - registers this race to the metamorphosis-handler.
handshake - confirms valid connection with the metamorphosis-handler.
metamorphosis - conducts all valid tests, scheduling and metamorphosis on unit -unit.

-unit
Valid input is unit.id.
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
-- Initialize random number generator. All potentially bow down and potentially prey to RNGesus!!!
-- --------------------------------------------------
math.randomseed(os.time())
math.random(); math.random(); math.random()

-- --------------------------------------------------
-- Declare local variables
-- --------------------------------------------------
units = units or {}
historicalFigures = historicalFigures or {}
local races = { 'dwarf' }
local this = 'metamorphosis-dwarf'
-- --------------------------------------------------
-- This variable establishes the dimensions that exist and whether they should be respected (the creature keeps its ), by default, when a metamorphosis occurs.
--[[ Valid transformation flags are:

	'root'
	If true, when an unitialized unit is first processed, it will only select transformations with ['root'] = true, unless there are none available to it. Initialized units will always ignore transformations with ['root'] = true. 'minAge' and 'maxAge' should both be set to 0 for transformations with the 'root' flag.
	'conditional'
	If true, will pass the transformation and unit to the 'Conditionals' function. This function should branch based upon the transformation it recieves, and contain the conditional logic for each transformation within it's own branch, returning true for is a valid transformation to take, and false for is not a valid transformation to take.
	If the conditions return true when the transformation is scheduled, then it will not be checked again until the scheduled time. If the conditions are then false, and the creature should have completed a different transformation earlier in its life, it will instead choose a valid one of those, even if it is after the maxAge for that transformation.
	
	Valid transformation flags should be entered as indexes to transformations[TransformationID]['flags'] in the follwoing manner:
	
	transformations[TransformationID]['flags'][FlagID] = true
	
	For example:
	
	transformations['MaleDwarf']['flags']['conditional'] = true
	
-]]
local transformations = {
	['MaleDwarf'] = {
	['from'] = { { ['Race'] = races[1], ['Caste'] = 'MALE' } },
	['to'] = { ['Race'] = 'elf', ['Caste'] = 'MALE' },
	['minAge'] = 95,
	['maxAge'] = 105,
	['weight'] = 1,
	['flags'] = {}	},
	
	['FemaleDwarf'] = {
	['from'] = { { ['Race'] = races[1], ['Caste'] = 'FEMALE' } },
	['to'] = { ['Race'] = 'elf', ['Caste'] = 'FEMALE' },
	['minAge'] = 95,
	['maxAge'] = 105,
	['weight'] = 1,
	['flags'] = {},	},
	}

-- --------------------------------------------------
-- Declare all functions
-- --------------------------------------------------

-- --------------------------------------------------
-- End-user functions
-- This section handles everything, from initial transformations, to scheduling, to everything.
-- This is the function that is defined by the creator of the modded race, and should be the only function that they need to edit.

function Conditionals(index, unit)
	local result = true
	-- if transformations[index] then
	-- print ('Do Stuff here')
	-- assign true or false to result
	-- end
	return result
end

function Metamorphosis(index, unit)
	if transformations[index] then
		dfhack.run_script('modtools/transform-unit', 'unit', tostring(unit.id), '-duration', 'forever', '-setPrevRace', '-keepInventory', '-race', transformations[index]['to']['Race'].name, '-caste', transformations[index]['to']['Caste'], '-suppressAnnouncement')
		
		Process(unit)
	else
		qerror ('Invalid Tranfomation Index')
	end
	-- print ('Do Stuff here')
	-- end
end

-- --------------------------------------------------
-- --------------------------------------------------

function Process(unit, historicalFigure)
	-- unit Branch
	if unit then
		print ('Processing unit ' .. unit.id)
		
		if units[unit]['initialized'] and units[unit]['transform'] then
			Metamorphosis(units[unit]['transform'], unit)
		else
			if not units[unit] or units[unit]['initialized'] == false then
				print ('Initializing unit record.')
				units[unit] = { ['initialized'] = false, ['transform'] = nil, ['Year'] = 0, ['Tick'] = 0 }
			end
			
			print ('Finding eligable transformations.')
			local transforms = {}
			if not units[unit]['initialized'] then
				for transform, transformData in pairs(transformations) do
					if transform['flags']['root'] and tableContains(transformData['from'], unit.race, 'Race') and tableContains(transformData['from'], unit.caste, 'Caste') and not tableContains(transforms, transform) then
						transforms.insert(transform)
					end
				end
			end
			
			if NumberOfKeys(transforms) == 0 then
				for transform, transformData in pairs(transformations) do
					if tableContains(transformData['from'], unit.race, 'Race') and tableContains(transformData['from'], unit.caste, 'Caste') and not tableContains(transforms, transform) then
						transforms.insert(transform)
					end
				end
			end
			
			-- Get unit age.
			local ageYears = df.global.cur_year - unit.birth_year
			local ageTicks = df.global.cur_year_tick - unit.birth_time
			
			if ageTicks < 0 then
				ageTicks = 403200 + ageTicks
				ageYears = ageYears - 1
			end
			print ('Unit ' .. unit.id .. ' is ' .. ageYears .. ' years and ' .. ageTicks .. ' ticks old.')
			
			if units[unit]['initialized'] and reversible then
				print ('Checking for reverse transformations.')
				for index, transform in pairs(transformation) do
					if transform['to']['Race'] == unit.race and transform['to']['Caste'] == unit.caste and transform['minAge'] > ageYears then
						dfhack.run_script('modtools/transform-unit', 'unit', tostring(unit.id), '-keepInventory', '-suppressAnnouncement', '-untransform')
					end
				end
			else
				local count = NumberOfKeys(transforms)
				
				if count == 1 then
					print (count .. ' transform possible')
				else
					print (count .. ' transforms possible')
				end
				
				if count > 0 then
					print ('Checking for conditions')
					for index, transform in pairs(transforms) do
						if transform['flags']['conditional'] then
							local var = Conditionals(index, unit)
							if var == false then
								transforms.remove(index)
							end
						end
					end
				end
				
				if count == 0 then
					print ('Scheduling for no future metamorphosis.')
					dfhack.run_script('metamorphosis-handler', '-flag', 'schedule', '-unit', tostring(unit.id), '-scheduleYear', tostring(-1), '-scheduleTick', tostring(-1))
				elseif count == 1 then
					for index, transform in pairs(transforms) do
						units[unit]['transform'] = transform
					end
				else
					print ('Selecting one of multiple possible transformations by weight.')
					-- Get weight range of results
					local weightTotal = 0
					for index, transform in pairs(transforms) do
						weightTotal = weightTotal + transform['weight']
					end
					
					-- roll random number between 1 and weightTotal inclusively
					local roll = math.random(weightTotal)
					
					-- iterate running wieght to get selected Transform
					local runningWeight = 0
					for index, transform in pairs(transforms) do
						runningWeight = runningWeight + transform['weight']
						if roll <= runningWeight then
							units[unit]['transform'] = transform
							print ('Transform' .. index .. ' selected.')
							break
						end
					end
				end
				
				if not units[unit]['transform']['flags']['root'] then
					print ('Calculating time of next transformation.' )
					local targetYear = unit.birth_year + math.random(units[unit]['transform']['minAge'], units[unit]['transform']['maxAge'])
					local targetTick = unit.birth_year_tick + math.random(403199)
					
					if targetTick >= 403200 then
						targetTick = targetTick - 403200
						targetYear = targetYear + 1
					end
					
					if targetYear <= df.global.cur_year and targetTick <= df.global.cur_year_tick then
						print ('Next transformation is immediate.' )
						Metamorphosis(units[unit]['transform'], unit)
					else
						print ('Next transformation is on year ' .. targetYear .. ', tick ' .. targetTick .. '.' )
						dfhack.run_script('metamorphosis-handler', '-flag', 'schedule', '-unit', tostring(unit.id), '-scheduleYear', tostring(targetYear), '-scheduleTick', tostring(targetTick))
					end
				else
					Metamorphosis(units[unit]['transform'], unit)
				end
			end
		end
		
	-- historicalFigure Branch
	elseif historicalFigure then
		print ('Processing historicalFigure not yet implemented.')
	end
end

-- --------------------------------------------------
-- Taken from animal-control.lua and modified.
-- This function checks if args.race is a raceID or raceName. If a name, it finds the matching ID and assigns it to args.race.
function ValidateRace(race)
	if race then
		if not tonumber(race) then
			print ('Race provided is not numerical ID')
			race = string.upper(race)
			print ('Race string is ' .. race)
			local raceID
			for i,c in ipairs(df.global.world.raws.creatures.all) do
				if c.creature_id == race then
					raceID = i
					break
				end
			end
			
			if not raceID then
				qerror('Invalid race: ' .. race)
			end
			race = raceID
			print ('Numerical ID for race is ' .. race)
		end
		
		return race;
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
-- This function returns true if table contains value.
function tableContains(varTable, varValue, key)
	key = key or nil
	
	local result = false
	if varTable and varValue then
		if key then
			for _, tableData in pairs(varTable) do
				if tableData[key] then
					if tableData[key] == value then
						result = true
						break
					end
				end
			end
		else
			for index, value in pairs(varTable) do
				if tonumber(index) then
					if value == varValue then
						result = true
						break
					end
				end
			end
		end
	end
	
	return result
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
-- Script execution starts here
-- --------------------------------------------------
-- Prints help if no flag is entered, or if flag == help.
if not args.flag or args.flag == 'help' then
	print (help)
-- --------------------------------------------------
-- redister Branch: Script calls metamorphosis-handler and adds this race and script to it.
elseif args.flag == 'register' then
	for index,race in pairs(races) do
		races[index] = ValidateRace(race)
	end
	
	for transform, transformData in pairs(transformations) do
		transformData['to'] = ValidateRace(transformData['to'])
		
		for index, form in pairs(transformData['from']) do
			form['Race'] = ValidateRace(form['Race'])
		end
	end
	
	if dfhack.findScript('metamorphosis-handler') then
		for index, race in pairs(races) do
			dfhack.run_script('metamorphosis-handler', '-flag', 'addRace', '-race', tostring(race), '-script', tostring(this))
		end
	else
		qerror ('dfhack failed to find metamorphosis-handler.')
	end
-- --------------------------------------------------
-- handshake Branch: returns true when called.
elseif args.flag == 'handshake' then
	print ('Handshake successful')
	return true
-- --------------------------------------------------
-- metamorphosis Branch: Performs all checks, validatiuons and transformations defined here in the race-specific metamorphosis script, under the process function.
elseif args.flag == 'metamorphosis' then
	if args.unit then
		ValidateUnit()
		
		Process(args.unit, nil);
	elseif historicalFigure then
		-- Implement ValidateHistoricalFigure()
		
		Process(nil, args.historicalFigure);
	else
		qerror ('metamorphosis Branch: Requires either -unit or -historicalFigure args. If both are provided, will only process -unit arg.')
	end
-- --------------------------------------------------
-- Invalid Flag error message.
else
	qerror ('Invalid flag ' .. args.flag .. '. Run script with no flag or with \'-flag help\' to get the flag and argument lists.')
end