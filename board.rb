require_relative 'manifest'

class Board

  NULL_PIECE = NullPiece.new()

  attr_reader :grid, :size, :taken_pieces, :kings
  attr_accessor :piece_in_hand, :current_player

  def initialize(dup = false)
    @size = 8
    @grid = Array.new(size) { Array.new(size) { NULL_PIECE } }
    @taken_pieces = []
    @piece_in_hand = NULL_PIECE
    @kings = {}
    populate unless dup
    @current_player = :white
  end

  # places pieces on the board
  # => Currently return value is just the positions of the last placed piece
  def populate
    add_pieces(Rook, [[0, 0], [0, 7], [7, 0], [7, 7]])
    add_pieces(Bishop, [[0, 2], [0, 5], [7, 2], [7, 5]])
    add_pieces(King, [[0, 4], [7, 4]])
    add_pieces(Knight, [[0, 1], [0, 6], [7, 1], [7, 6]])
    add_pieces(Queen, [[0, 3], [7, 3]])
    add_pawns(1)
    add_pawns(6)
  end

  # Instantiate the appropriate number of rooks and add them to the board,
  # => Currently return value is just an array of the positions where the rook was placed
  def add_pieces(klass, positions)
    positions.each do |pos|
      color = (pos[0] < 2) ? :black : :white
      piece = klass.new(color, pos, self)
      self[pos] = piece
      @kings[color] = piece if piece.is_a?(King)
    end
  end

  def add_pawns(row)
    color = row < 2 ? :black : :white
    @grid[row].each_with_index do |el, i|
      @grid[row][i] = Pawn.new(color, [row, i], self)
    end
  end

  # Takes a start and end_pos, each in the form [row, column]
  # Attempts to place the piece in end_pos, putting it back in start
  # if it is unable to place it in end_pos.
  def move(start, end_pos)
    raise BadInputError, "No move selected" if start == end_pos
    piece = self[start]
    place_piece(piece, end_pos)
    remove_piece(start)
    piece.has_moved = true
    piece.move_history << end_pos
    handle_castle!(start, end_pos)
    piece
  end

  def handle_castle!(start, end_pos)
    return unless piece_in_hand.is_a?(King)
    return unless (end_pos[1] - start[1]).abs > 1
    case end_pos[1]
    when 2
      move!([end_pos[0], 0], [end_pos[0], 3])
      self[[end_pos[0], 3]].has_moved = true
    when 6
      move!([end_pos[0], 7], [end_pos[0], 5])
      self[[end_pos[0], 5]].has_moved = true
    end
  end

  def drop_piece
    self.piece_in_hand = NULL_PIECE
  end

  # Takes a position in the form [row, column] and returns true if
  # that position on the board contains the null piece
  def empty?(pos)
    self[pos].is_a?(NullPiece)
  end


  # Takes a position in the form [row, column] and returns true if
  # that position is within the bounds of the board
  def in_bounds?(pos)
    pos.all? { |coord| coord.between?(0, size - 1)}
  end

  # Takes a position in the form [row, column] and returns the element
  # at that position from the grid
  def [](pos)
    row, col = pos
    grid[row][col]
  end

  # Takes a position in the form [row, column] and a piece;
  # sets the grid at position to reference the piece.
  # => Returns the piece
  def []=(pos, piece)
    row, col = pos
    grid[row][col] = piece
  end

  # Takes a piece and an end_pos in the form [row, column]
  # Places the piece in a new location, if that location is valid.
  # Raises a BadMoveError if the move is invalid
  # Remembers taken piece if a piece was taken.
  def place_piece(piece, end_pos)
    raise BadMoveError, "Cannot move #{piece.class} to #{end_pos}" unless piece.filter_moves.include?(end_pos)
    @taken_pieces << self[end_pos] unless self.empty?(end_pos)
    self[end_pos] = piece
    piece.position = end_pos
  end

  # Takes a position on the board in the form [row, column]
  # Places a Null Piece at that location unless the location was empty.
  def remove_piece(start)
    raise BadInputError, "Tried to remove nonexistent piece at #{start}" if self.empty?(start)
    self[start] = NULL_PIECE
  end

  def dup
    new_board = Board.new(true)
    grid.each.with_index do |row, row_index|
      row.each.with_index do |square, column_index|
        new_square = square.dup(new_board)
        new_board[[row_index, column_index]] = new_square
        new_board.kings[new_square.color] = new_square if new_square.is_a?(King)
      end
    end
    new_board
  end

  def king_in_checkmate?(color)
    return false unless king_in_check?(color)
    kings_army = grid.flatten.select do |piece|
      piece.color == color
    end
    kings_army.all? do |piece|
      piece.filter_moves.empty?
    end
  end

  def stalemate?
    return false if king_in_check?(@current_player)
    kings_army = grid.flatten.select do |piece|
      piece.color == @current_player
    end
    kings_army.all? do |piece|
      piece.filter_moves.empty?
    end
  end

  def in_check?(start, end_pos)
    toy_board = self.dup
    piece = toy_board[start]
    toy_board.move!(start, end_pos)
    toy_board.king_in_check?(piece.color)
  end

  def move!(start, end_pos)
    self[end_pos] = self[start]
    self[end_pos].position = end_pos
    self[start] = NullPiece.new()
  end

  def king_in_check?(color)
    return kings[color].in_check?
  end

  def find_king(color)
    kings[color].position
  end

  def switch_players!
    grid.each do |row|
      row.each do |square|
        square.clear_moves
      end
    end
    self.current_player = current_player== :white ? :black : :white
  end

end
