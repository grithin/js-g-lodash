`global= (typeof(global) != 'undefined' && global)  || (typeof(window) != 'undefined' && window) || this`
_ = global.lodash || global._ || require('lodash')
global._ = _ # overwrite potential underscore

# Add, but only if unique
_.addUnique = (v, a) ->
	if _.indexOf(a, v) == -1
		a[a.length] = v
	return

# get the first available key in a sequential array (where potentially some have been deteted

_.firstAvailableKey = (a) ->
	i = 0
	while i < a.length
		if typeof a[i] == 'undefined'
			return i
		i++
	a.length

# insert on first available key in a sequential array.  Returns key.

_.onAvailable = (v, a) ->
	key = _.firstAvailableKey(a)
	a[key] = v
	key

# get key of first existing element

_.firstKey = (a) ->
	i = 0
	while i < a.length
		if typeof a[i] != 'undefined'
			return i
		i++
	false

# get first existing element

_.firstValue = (a) ->
	key = _.firstKey(a)
	a[key]

# ignore unset elements (since deleted values still count towards length)

_.count = (a) ->
	count = 0
	for i of a
		count += 1
	count

#  see jquery

_.isNumeric = (v) ->
	if typeof v == typeof 1 or typeof v == typeof '1'
		return obj - parseFloat(obj) + 1 >= 0
	return

# set arbitrarily deep path to value use standard http form array input semantics

###*
ex
	setValue('interest[1][name]','test',data);  => { interest: { '1': { name: 'test' } } }
###

_.setValue = (name, value, obj) ->
	nameParts = name.replace(/\]/g, '').split(/\[/)
	current = obj
	i = 0
	while i < nameParts.length - 1
		if !current[nameParts[i]]
			current[nameParts[i]] = {}
		#since objs are moved by reference, this obj attribute of parent obj still points to parent attribute obj
		current = current[nameParts[i]]
		i++
	current[nameParts[nameParts.length - 1]] = value
	return

# Binary to decimal

_.bindec = (bin) ->
	bin = (bin + '').split('').reverse()
	dec = 0
	i = 0
	while i < bin.length
		if bin[i] == 1
			dec += 2 ** i
		i++
	dec

# Decimal to binary

_.decbin = (dec) ->
	bits = ''
	into = dec
	while into >= 1
		bits += into % 2
		into = Math.floor(into / 2)
	lastBit = Math.ceil(into)
	if lastBit
		bits += lastBit
	bits.split('').reverse().join ''

# set words to upper case

### better, non-dependent, coffee version
_.ucwords = (string)->
	if string
		return (string.split(' ').map (v)->
			v[0].toUpperCase() + v[1..]).join(' ')
###

_.ucwords = (string) ->
	if string
		string = string.split(' ')
		newString = Array()
		i = 0
		$.each string, ->
			newString[newString.length] = @substr(0, 1).toUpperCase() + @substr(1, @length)
			return
		return newString.join(' ')
	return

#  show number or string as some string-number with some amount of decimals

_.decimals = (string, precision) ->
	string = _.round(string, precision) + ''
	parts = string.split('.')
	if parts.length == 2
		remaining = precision - (parts[1].length)
		string + '0'.repeat(remaining)
	else if precision > 0
		string + '.' + '0'.repeat(precision)
	else
		string

# htmlspecialchars() - for escaping text

_.hsc = (string) ->
	if string == null
		return ''
	_.escape(string)
	# seems to be not-uneccesary to use jquery for this
	# $('<a></a>').text(string).html()

_.nl2br = (string) ->
	string.replace /(?:\r\n|\r|\n)/g, '<br />'
_.br_hsc = (string)->
	_.nl2br _.hsc(string)

# flatten keys of object with . separation

_.flatten_keys = (data) ->
	result = {}

	recurse = (cur, prop) ->
		if Object(cur) != cur or Array.isArray(cur)
			result[prop] = cur
		else
			isEmpty = true
			for p of cur
				isEmpty = false
				recurse cur[p], if prop then prop + '.' + p else p
			if isEmpty and prop
				result[prop] = {}
		return

	recurse data, ''
	result

# turn a js object into form-name-style flat object.  Ex {bob:{bobs:'bill'}} => {'bob[bobs]':'bill'}

# @NOTE  does not mutate object
_.flatten_to_input = (data) ->
	flat = _.flatten_keys(data)
	bracketFlat = {}
	name = undefined
	# remove the "." separation
	for k of flat
		name = k
		# add "[]" to array values
		if Array.isArray(flat[k])
			name += '[]'
		parts = name.split('.')
		if parts.length > 1
			#first key is not bracketted: ex: bob[bill]
			first = parts.shift()
			parts = parts.map((v) ->
				'[' + v + ']'
			)
			newKey = first + parts.join('')
			bracketFlat[newKey] = flat[k]
		else
			bracketFlat[name] = flat[k]
	bracketFlat

# @NOTE does not mutate object
_.unflatten_input = (o)->
	if _.isArray(o) || !_.isObject(o)
		throw new Error('wrong type')
	new_o = {}
	for k, v of o
		_.set(new_o, k, v)
	new_o

# for some object, flatten some keys
# @NOTE mutates object
_.flatten_parts_to_input = (o, parts)->
	if _.isArray(o) || !_.isObject(o)
		throw new Error('wrong type')
	picked = _.pick(o,parts)
	flat = _.flatten_to_input(picked)
	for k of picked
		delete o[k]
	o = _.assign(o, flat)
# unflatten some keys, based on original unflat key name
# @NOTE mutates object
_.unflatten_input_parts = (o, parts)->
	if _.isArray(o) || !_.isObject(o)
		throw new Error('wrong type')
	keys = []
	for k of o
		if parts.indexOf(k.split('[',1)[0]) != -1
			keys.push k
	picked = _.pick(o,keys)
	unflat = _.unflatten_input(picked)

	for k in keys
		delete o[k]
	o = _.assign(o, unflat)

# like map, but uses and returns obj instead of array

_.morph = (obj, fn) ->
	for key of obj
		obj[key] = fn(obj[key], key)
	obj

_.morphCopy = (obj, fn) ->
	copy = undefined
	if _.isArray(obj)
		copy = []
	else
		copy = {}
	#copy = new obj.constructor()
	for key of obj
		if obj.hasOwnProperty(key)
			copy[key] = fn(obj[key], key)
	copy

# _.lastOf(['bill','no','no'], ['bill','no','bills']) #> {position: 2, needle: "no"}
_.lastOf =(haystack, needles)->
	last_position = -1
	last_needle = false
	for needle, i in needles
		position = haystack.lastIndexOf needle
		if position > last_position
			last_position = position
			last_needle =  needle
	return {position: last_position, needle: last_needle}
# bind all functions to self
_.bindSelf = (obj)->
	_.functions(obj).map (key)-> # bind keys to self
		obj[key] = obj[key].bind(obj)



# turn an object into an instance with "this" mapped to the object keys.  Useful when a pre-keyed "this" is needed
_.makeInstance = (obj)->
	new ()->
		for k,v of obj
			@[k] = v
		@


# like memoize, but only returns cache on consecutive-same calls
_.re_call = (callback, key_resolver)->
	re_call = ()->
		key = key_resolver?.apply(this, arguments) || arguments
		if _.isEqual(re_call.last_key, key)
			return re_call.last_result
		result = callback.apply(this,arguments)
		re_call.last_key = key
		re_call.last_result = result

		return result
	re_call.cache = new WeakMap
	return re_call
# catch JSON.parse exception and warn.  chrome error-on-bad-json-syntax is cryptic, so, instead, grab and warn
_.tryJSON = (json)->
	try
		return JSON.parse(json)
	catch e
		return undefined
# find obj difference with dot notation
_.compare = (o1, o2)->
	o1_flat = _.flatten_keys(o1)
	o2_flat = _.flatten_keys(o2)
	o1_keys = _.keys(o1_flat)
	o2_keys = _.keys(o2_flat)
	diff = {}
	diff.missing_in_o2 = _.difference(o1_keys, o2_keys)
	diff.missing_in_o1 = _.difference(o2_keys, o1_keys)
	same_keys = _.intersection(o1_keys, o2_keys)
	diff.value_diff = {}
	for key in same_keys
		if o1_flat[key] != o2_flat[key]
			diff.value_diff[key] = {o1:o1_flat[key], o2:o2_flat[key]}
	diff

# push if arg is not array, otherwise push each of array
_.pushes = (arr, adds)->
	if _.isArray(adds)
		for add in adds
			arr.push(add)
	else
		arr.push(adds)
	arr

# take a list of functions, and return a list of those functions with a shared context object between them as the first argument
### Ex
sequence = [
	(context, result)-> Promise.delay(1000).then(()->'bob1'),
	(context, result)-> Promise.delay(100).then(()->'bob2'),
]
Promise.sequence(_.contexted(sequence)).then (r)->
	c arguments
###
_.contexted = (list, context={})->
	context={}
	list.map (fn)-> _.partial(fn, context)


# convert to number, w/o NaN
_.int = (v)->
	parseInt(v) || 0
# convert to number, w/o NaN
_.float = (v)->
	parseFloat(v) || 0.0
_.number = (v)->
	_.toNumber(v) || 0
# if not array, make array with `v` as first element
_.array = (v)->
	if !_.isArray(v)
		return [v]
	return v

# Without a `conform` fn, comforms array values to the searched value for comparison, and returns true or false
_.in = (arr, v, comform)->
	if !conform
		if _.isString(v)
			conform = (v)-> ''+v
		else if _.isInteger(v)
			conform = (v)-> parseInt v
		else if _.isNumber(v)
			conform = (v)-> parseFloat v
		else
			conform = (v)-> v

	for arr_v in arr
		conformed = conform(arr_v)
		if conformed == v
			return true
	return false

# filter on exact match
_.delete = (arr, match)->
	arr.filter (v)->
		v != match