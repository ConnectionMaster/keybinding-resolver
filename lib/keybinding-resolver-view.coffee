{Disposable, CompositeDisposable} = require 'atom'
{$$, View} = require 'atom-space-pen-views'

module.exports =
class KeyBindingResolverView extends View
  @content: ->
    @div class: 'key-binding-resolver', =>
      @div class: 'panel-heading padded', =>
        @span 'Key Binding Resolver: '
        @span outlet: 'keystroke', 'Press any key'
      @div outlet: 'commands', class: 'panel-body padded'

  initialize: ->
    @on 'click', '.source', (event) -> atom.workspace.open(event.target.innerText)

  serialize: ->
    attached: @panel?.isVisible()

  destroy: ->
    @detach()

  toggle: ->
    if @panel?.isVisible()
      @detach()
    else
      @attach()

  attach: ->
    @disposables = new CompositeDisposable

    @panel = atom.workspace.addBottomPanel(item: this)
    @disposables.add new Disposable =>
      @panel.destroy()
      @panel = null

    @disposables.add atom.keymaps.onDidMatchBinding ({keystrokes, binding, keyboardEventTarget}) =>
      @update(keystrokes, binding, keyboardEventTarget)

    @disposables.add atom.keymaps.onDidPartiallyMatchBindings ({keystrokes, partiallyMatchedBindings, keyboardEventTarget}) =>
      @updatePartial(keystrokes, partiallyMatchedBindings)

    @disposables.add atom.keymaps.onDidFailToMatchBinding ({keystrokes, keyboardEventTarget}) =>
      @update(keystrokes, null, keyboardEventTarget)

  detach: ->
    @disposables?.dispose()

  update: (keystrokes, keyBinding, keyboardEventTarget) ->
    @keystroke.html $$ ->
      @span class: 'keystroke', keystrokes

    unusedKeyBindings = atom.keymaps.findKeyBindings({keystrokes, target: keyboardEventTarget}).filter (binding) ->
      binding isnt keyBinding

    unmatchedKeyBindings = atom.keymaps.findKeyBindings({keystrokes}).filter (binding) ->
      binding isnt keyBinding and binding not in unusedKeyBindings

    @commands.html $$ ->
      @table class: 'table-condensed', =>
        if keyBinding
          @tr class: 'used', =>
            @td class: 'command', keyBinding.command
            @td class: 'selector', keyBinding.selector
            @td class: 'source', keyBinding.source

        for binding in unusedKeyBindings
          @tr class: 'unused', =>
            @td class: 'command', binding.command
            @td class: 'selector', binding.selector
            @td class: 'source', binding.source

        for binding in unmatchedKeyBindings
          @tr class: 'unmatched', =>
            @td class: 'command', binding.command
            @td class: 'selector', binding.selector
            @td class: 'source', binding.source

  updatePartial: (keystrokes, keyBindings) ->
    @keystroke.html $$ ->
      @span class: 'keystroke', "#{keystrokes} (partial)"

    @commands.html $$ ->
      @table class: 'table-condensed', =>
        for binding in keyBindings
          @tr class: 'unused', =>
            @td class: 'command', binding.command
            @td class: 'keystrokes', binding.keystrokes
            @td class: 'selector', binding.selector
            @td class: 'source', binding.source
