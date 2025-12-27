# LibTSMReactive

The Reactive framework is based around observable state objects. One of the primary goals of
the Reactive framework is make it easy to build state-driven UI, where the UI can respond to
specific state fields being updated without needing to completely rerender the entire UI. For
example, if we have a UI that displays the player's current amount of gold among other player
statistics, we only need to update the player gold text content when that value changes,
rather than redrawing the entire window.

## Documentation

See [the docs](https://tradeskillmaster.github.io/LibTSMReactive) for complete documentation and
usage, as well as for an example which demonstrates its main features.

## Dependencies

This library has the following external dependencies which must be installed separately within the
target application:

* [LibTSMClass](https://github.com/TradeSkillMaster/LibTSMClass)
* [LibTSMCore](https://github.com/TradeSkillMaster/LibTSMCore)
* [LibTSMUtil](https://github.com/TradeSkillMaster/LibTSMUtil)

## Installation

If you're using the [BigWigs packager](https://github.com/BigWigsMods/packager), you can reference
LibTSMReactive as an external library.

```yaml
externals:
  Libs/LibTSMReactive:
    url: https://github.com/TradeSkillMaster/LibTSMReactive.git
```

Otherwise, you can download the
[latest release directly from GitHub](https://github.com/TradeSkillMaster/LibTSMReactive/releases).

## License and Contributions

LibTSMReactive is licensed under the MIT license. See LICENSE.txt for more information. If you
would like to contribute to LibTSMReactive, opening an issue or submitting a pull request against
the [LibTSMReactive GitHub project](https://github.com/TradeSkillMaster/LibTSMReactive) is highly
encouraged.
