JumpTo = require "../../lib/commands/jump-to"

describe "JumpTo", ->
  editor = null

  beforeEach ->
    waitsForPromise -> atom.workspace.open("empty.markdown")
    runs -> editor = atom.workspace.getActiveTextEditor()

  describe ".trigger", ->
    it "triggers correct command", ->
      jumpTo = new JumpTo("next-heading")
      spyOn(jumpTo, "nextHeading")

      jumpTo.trigger(abortKeyBinding: -> {})

      expect(jumpTo.nextHeading).toHaveBeenCalled()

    it "jumps to correct position", ->
      jumpTo = new JumpTo("previous-heading")

      jumpTo.previousHeading = -> [5, 5]
      spyOn(jumpTo.editor, "setCursorBufferPosition")

      jumpTo.trigger()

      expect(jumpTo.editor.setCursorBufferPosition).toHaveBeenCalledWith([5, 5])

  describe ".previousHeading", ->
    text = """
    # Title

    content content

    ## Subtitle

    content content
    """

    it "finds nothing if no headings", ->
      jumpTo = new JumpTo()
      expect(jumpTo.previousHeading()).toBe(false)

    it "finds nothing if no previous heading", ->
      editor.setText(text)
      editor.setCursorBufferPosition([0, 1])

      jumpTo = new JumpTo()
      expect(jumpTo.previousHeading()).toEqual(false)

    it "finds previous subtitle", ->
      editor.setText(text)
      editor.setCursorBufferPosition([6, 6])

      jumpTo = new JumpTo()
      expect(jumpTo.previousHeading()).toEqual(row: 4, column: 0)

    it "finds previous title", ->
      editor.setText(text)
      editor.setCursorBufferPosition([4, 1])

      jumpTo = new JumpTo()
      expect(jumpTo.previousHeading()).toEqual(row: 0, column: 0)

  describe ".nextHeading", ->
    text = """
    # Title

    content content

    ## Subtitle

    content content
    """

    it "finds nothing if no headings", ->
      jumpTo = new JumpTo()
      expect(jumpTo.nextHeading()).toBe(false)

    it "finds next subtitle", ->
      editor.setText(text)
      editor.setCursorBufferPosition([3, 6])

      jumpTo = new JumpTo()
      expect(jumpTo.nextHeading()).toEqual(row: 4, column: 0)

    it "finds top title", ->
      editor.setText(text)
      editor.setCursorBufferPosition([6, 5])

      jumpTo = new JumpTo()
      expect(jumpTo.nextHeading()).toEqual(row: 0, column: 0)

  describe ".referenceDefinition", ->
    text = """
    link to [content][]

    [content]: http://content

    footnotes[^fn] is a special link

    [^fn]: footnote definition
    """

    it "finds nothing if no word under cursor", ->
      jumpTo = new JumpTo()
      expect(jumpTo.referenceDefinition()).toBe(false)

    it "finds nothing if no link found", ->
      editor.setText(text)
      editor.setCursorBufferPosition([0, 2])

      jumpTo = new JumpTo()
      expect(jumpTo.referenceDefinition()).toBe(false)

    describe "links", ->
      beforeEach -> editor.setText(text)

      it "finds definition", ->
        editor.setCursorBufferPosition([0, 16])
        jumpTo = new JumpTo()
        expect(jumpTo.referenceDefinition()).toEqual([2, 8])

      it "finds reference", ->
        editor.setCursorBufferPosition([2, 2])
        jumpTo = new JumpTo()
        expect(jumpTo.referenceDefinition()).toEqual([0, 16])

    describe "foonotes", ->
      beforeEach -> editor.setText(text)

      it "finds definition", ->
        editor.setCursorBufferPosition([4, 12])
        jumpTo = new JumpTo()
        expect(jumpTo.referenceDefinition()).toEqual([6, 4])

      it "finds reference", ->
        editor.setCursorBufferPosition([6, 4])
        jumpTo = new JumpTo()
        expect(jumpTo.referenceDefinition()).toEqual([4, 13])

  describe ".nextTableCell", ->
    beforeEach ->
      editor.setText """
      this is a table:

      | Header One | Header Two |
      |:-----------|:-----------|
      | Item One   | Item Two   |

      this is another table:

      Header One    |   Header Two | Header Three
      :-------------|-------------:|:-----------:
      Item One      |     Item Two |  Item Three
      """

    it "finds nothing if it is not a table row", ->
      editor.setCursorBufferPosition([0, 2])
      jumpTo = new JumpTo()
      expect(jumpTo.nextTableCell()).toBe(false)

    it "finds row 1, cell 2 in table 1", ->
      editor.setCursorBufferPosition([2, 2])
      jumpTo = new JumpTo()
      expect(jumpTo.nextTableCell()).toEqual([2, 25])

    it "finds row 2, cell 1 in table 1 from end of row 1", ->
      editor.setCursorBufferPosition([2, 25])
      jumpTo = new JumpTo()
      expect(jumpTo.nextTableCell()).toEqual([4, 10])

    it "finds row 2, cell 1 in table 1 from row separator", ->
      editor.setCursorBufferPosition([3, 0])
      jumpTo = new JumpTo()
      expect(jumpTo.nextTableCell()).toEqual([4, 10])

    it "finds row 1, cell 3 in table 2", ->
      editor.setCursorBufferPosition([8, 24])
      jumpTo = new JumpTo()
      expect(jumpTo.nextTableCell()).toEqual([8, 43])

    it "finds row 2, cell 1 in table 2", ->
      editor.setCursorBufferPosition([8, 42])
      jumpTo = new JumpTo()
      expect(jumpTo.nextTableCell()).toEqual([10, 8])
