require 'flags'

-- 5.3 compatibility
local unpack = unpack or table.unpack

TestFlags = {}

function TestFlags:setUp()
  flags.registered,flags.defaults = {},{}
  flags.parsed = flags.defaults

  flags.register ('boolean-flag', 'b', 'bool') {
    help = "Boolean flag.";
  }

  flags.register ('number-flag', 'n') {
    help = "Numeric flag.";
    type = flags.number;
    default = 4;
  }

  flags.register ('set-number-to-five') {
    key = 'number_flag';
    value = 5;
    help = "Same as --number-flag=5"
  }

  flags.register ('string-flag', 's') {
    help = "String flag.";
    type = flags.string;
  }

  flags.register 'string-list-flag' {
    help = "List[String] flag.";
    type = flags.list;
  }

  flags.register ('number-list-flag', 'L') {
    help = "List[Number] flag.";
    type = flags.listOf(flags.number, ':');
  }

  flags.register ('required-flag', 'r') {
    required = true;
  }
end

function TestFlags:testDefaultValue()
  lu.assertEquals(flags 'number-flag', 4)
  lu.assertEquals(flags.parsed.number_flag, 4)
end

function TestFlags:testAllowMissing()
  -- Without allow_missing=true, this would throw.
  lu.assertEquals(flags.parse({'--boolean-flag'}, false, true),
                  {boolean_flag = true})
end

function TestFlags:testAllowUndefined()
  lu.assertEquals(flags.parse({'a', 'b', '-r', '-s', 'foo', '--bar'}, true),
                  {'a', 'b', '--bar', required_flag = true, string_flag = 'foo'})
end

function TestFlags:testFlagsRequire()
  flags.parse {'-r', '--string-flag=foo'}
  lu.assertEquals(flags.require "string-flag", "foo")
  lu.assertErrorMsgContains(
    "Required command line flag '--number-flag' was not provided.",
    flags.require, 'number-flag')
end

function TestFlags:testParseErrors()
  -- required flag missing
  lu.assertErrorMsgContains(
    "Required command line flag '--required-flag' was not provided.",
    flags.parse, {'--boolean-flag'})

  -- unexpected flag found
  lu.assertErrorMsgContains(
    "unrecognized option",
    flags.parse, {'--no-such-flag'})

  -- can't invert non-boolean flag
  lu.assertErrorMsgContains(
    "cannot be inverted",
    flags.parse, {'--no-number-flag'})
  lu.assertErrorMsgContains(
    "cannot be inverted",
    flags.parse, {'+n'})

  -- non-boolean flag requires an argument
  lu.assertErrorMsgContains(
    "requires an argument",
    flags.parse, {'--string-flag'})

  -- boolean flag doesn't permit an argument
  lu.assertErrorMsgContains(
    "doesn't allow an argument",
    flags.parse, {'--boolean-flag=true'})

  -- argument of wrong type
  lu.assertErrorMsgContains(
    "requires a numeric argument",
    flags.parse, {'--number-flag=asdf'})

  -- post hoc require() of a flag
  flags.parse{'--no-required-flag'}
  lu.assertErrorMsgContains(
    "Required command line flag '--boolean-flag' was not provided",
    flags.require, 'boolean-flag')
end

local function checkFlagValues()
  lu.assertEquals(flags 'boolean-flag', true)
  lu.assertEquals(flags 'number-flag', 6)
  lu.assertEquals(flags 'string-flag', 'kittens')
  lu.assertEquals(flags 'string-list-flag', { 'Epsilon', 'Suzie' })
  lu.assertEquals(flags 'number-list-flag', { 1, 2, 3 })
  lu.assertEquals(flags 'required-flag', false)
end
local cmdlines = {
  { name = "long dense options";
    '--boolean-flag', '--number-flag=6', '--string-flag=kittens',
    '--string-list-flag=Epsilon,Suzie', '--number-list-flag=1:2:3',
    '--no-required-flag'
  };
  { name = "short dense options";
    '-b', '-n6', '-skittens', '--string-list-flag=Epsilon,Suzie',
    '-L1:2:3', '+r'
  };
  { name = "long sparse options";
    '--bool', '--number-flag', '6', '--string-flag', 'kittens',
    '--string-list-flag', 'Epsilon,Suzie', '--number-list-flag', '1:2:3',
    '--no-required-flag'
  };
  { name = "short sparse options";
    '-b', '-n', '6', '-s', 'kittens', '--string-list-flag', 'Epsilon,Suzie',
    '-L1:2:3', '+r'
  };
}
for _,argv in ipairs(cmdlines) do
  TestFlags['testParseSuccess: '..argv.name] = function(self)
    flags.parse(argv)
    checkFlagValues()
  end
end

function TestFlags:testKeyValueOverride()
  flags.parse{'-r', '--set-number-to-five'}
  lu.assertEquals(flags 'number_flag', 5)
end

function TestFlags:testRegistrationErrors()
  lu.assertErrorMsgContains(
    'defined in multiple places',
    flags.register, 'boolean-flag')

  local flag = flags.register 'test-flag'
  lu.assertErrorMsgContains(
    'must not have default values',
    flag, { default = true, required = true })
end

function TestFlags:testKeyDefault()
  flags.register 'v' { default = 1, key = 'verbosity', value = 2 }
  lu.assertEquals(flags.parse {'-r'} .verbosity, 1)
  lu.assertEquals(flags.parse {'-r', '-v'} .verbosity, 2)
end

local HELP_TEXT = [[
        --boolean-flag  Boolean flag.
                    -b
                --bool
         --number-flag  Numeric flag.
                    -n
    --number-list-flag  List[Number] flag.
                    -L
       --required-flag  (no help text)
                    -r
  --set-number-to-five  Same as --number-flag=5
         --string-flag  String flag.
                    -s
    --string-list-flag  List[String] flag.]]
function TestFlags:testHelpText()
  lu.assertEquals(flags.help(), HELP_TEXT)
end

function TestFlags:testMapStringString()
  flags.register ('ssmap') {
    type = flags.map;
  }
  lu.assertEquals(
    flags.parse({ '--ssmap=foo=waffles,bar=kittens' }, true, true),
    { ssmap = { foo = 'waffles'; bar = 'kittens' } })
end

function TestFlags:testMapNumberList()
  flags.register ('nlmap') {
    type = flags.mapOf(flags.number, flags.list, ';', ':');
  }
  lu.assertEquals(
    flags.parse({ '--nlmap=10:a,b,c;20:d,e,f;30:g,h,i' }, true, true),
    { nlmap = { [10] = {'a','b','c'}; [20] = {'d','e','f'}; [30] = {'g','h','i'} } })
end
