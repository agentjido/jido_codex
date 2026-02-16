# This file contains the configuration for Credo and you are probably reading this after creating
# it with `mix credo.gen.config`.
#
# If you find anything wrong or unclear in this file, please report an issue on GitHub:
# https://github.com/rrrene/credo/issues

%{
  #
  # You can have as many configs as you like in the `configs:` field.
  configs: [
    %{
      #
      # Run any config using `mix credo -C <name>`. If no config name is given
      # "default" is used.
      #
      name: "default",
      #
      # These are the files included in the analysis:
      #
      files: %{
        included: ["lib/", "test/"],
        excluded: [~r"/_build/", ~r"/deps/", ~r"/node_modules/"]
      },
      #
      # Load any mix.exs config (usually the file contains plugins)
      # config_file: "mix.exs",
      #
      # If you create your own checks, you must specify the source files for
      # the checks to be loaded by Credo. Normally, you don't need to do this
      # unless you want to organize your Credo checks differently.
      #
      # sources: ["lib/", "test/", "priv/"],
      #
      # Credo has community checks and integrations with Elixir and Phoenix.
      # You can see them here: https://hex.pm/packages?search=credo
      #
      requires: [],
      #
      # If you want to enforce a style guide and need a more traditional linting
      # experience, you can change `strict` to `true` below:
      #
      strict: false,
      #
      # If you want to use unimported_namespace detection, remember to use
      # `mix credo explain` to learn more about it.
      #
      parse_timeout: 5000,
      #
      checks: [
        {Credo.Check.Design.AliasUsage,
         [priority: :low, if_nested_deeper_than: 2, if_called_more_often_than: 0]},
        {Credo.Check.Design.DuplicatedCode, [excluded_macros: []]},
        {Credo.Check.Design.SkipTestWithoutComment, []},
        {Credo.Check.Design.TagFIXME, []},
        {Credo.Check.Design.TagTODO, [exit_status: 0]},
        {Credo.Check.Readability.AliasOrder, []},
        {Credo.Check.Readability.FunctionNames, []},
        {Credo.Check.Readability.LargeNumbers, []},
        {Credo.Check.Readability.MaxLineLength, [priority: :low, max_length: 120]},
        {Credo.Check.Readability.ModuleAttributeNames, []},
        {Credo.Check.Readability.ModuleDoc, []},
        {Credo.Check.Readability.ModuleNames, []},
        {Credo.Check.Readability.ParenthesesInCondition, []},
        {Credo.Check.Readability.ParenthesesOnZeroArityDefs, []},
        {Credo.Check.Readability.PipeIntoAnonymousFunctions, []},
        {Credo.Check.Readability.PredicateFunctionNames, []},
        {Credo.Check.Readability.RedundantBlankLines, []},
        {Credo.Check.Readability.Semicolons, []},
        {Credo.Check.Readability.SpaceAfterCommas, []},
        {Credo.Check.Readability.StringSigils, []},
        {Credo.Check.Readability.TrailingBlankLine, []},
        {Credo.Check.Readability.TrailingWhiteSpace, []},
        {Credo.Check.Readability.VariableNames, []},
        {Credo.Check.Refactor.ABCSize, [priority: :low, max_size: 30]},
        {Credo.Check.Refactor.AppendSingleItem, []},
        {Credo.Check.Refactor.ConditionalsWithCommonFalseBlock, []},
        {Credo.Check.Refactor.CyclomaticComplexity, [max_complexity: 12]},
        {Credo.Check.Refactor.DoBlockNotation, []},
        {Credo.Check.Refactor.FilterFilterMap, []},
        {Credo.Check.Refactor.FunctionArity, []},
        {Credo.Check.Refactor.LongQuoteBlocks, []},
        {Credo.Check.Refactor.MapInto, []},
        {Credo.Check.Refactor.MapMap, []},
        {Credo.Check.Refactor.MatchInCondition, []},
        {Credo.Check.Refactor.NegatedConditionsInUnless, []},
        {Credo.Check.Refactor.NegatedConditionsWithElse, []},
        {Credo.Check.Refactor.Nesting, [max_nesting: 3]},
        {Credo.Check.Refactor.PipeChainStart,
         [excluded_argument_types: [:atom, :binary, :fn, :keyword], excluded_functions: []]},
        {Credo.Check.Refactor.RedundantWithFileRead, []},
        {Credo.Check.Refactor.RejectRejectMap, []},
        {Credo.Check.Refactor.UnlessWithElse, []},
        {Credo.Check.Refactor.UnusedKeywordKeys, []},
        {Credo.Check.Refactor.VariableRebinding, []},
        {Credo.Check.Warning.BoolOperationOnSameValues, []},
        {Credo.Check.Warning.ExpensiveEmptyEnumCheck, []},
        {Credo.Check.Warning.IExPry, []},
        {Credo.Check.Warning.IoInspect, []},
        {Credo.Check.Warning.LazyLoggingConditional, []},
        {Credo.Check.Warning.LeakyEnvironment, []},
        {Credo.Check.Warning.MapGetUnsafeNaive, []},
        {Credo.Check.Warning.MissedMetadataKeyInLoggerConfig, []},
        {Credo.Check.Warning.MixEnv, []},
        {Credo.Check.Warning.OperationOnSameValues, []},
        {Credo.Check.Warning.OperationWithConstantResult, []},
        {Credo.Check.Warning.RaiseInsideRescue, []},
        {Credo.Check.Warning.UnusedEnumOperation, []},
        {Credo.Check.Warning.UnusedFileOperation, []},
        {Credo.Check.Warning.UnusedKeywordOperation, []},
        {Credo.Check.Warning.UnusedListOperation, []},
        {Credo.Check.Warning.UnusedPathOperation, []},
        {Credo.Check.Warning.UnusedRegexOperation, []},
        {Credo.Check.Warning.UnusedStringOperation, []},
        {Credo.Check.Warning.UnusedTupleOperation, []},
        {Credo.Check.Warning.UnsafeExec, []}
      ]
    }
  ]
}
