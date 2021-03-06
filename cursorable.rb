require "io/console"

module Cursorable
  KEYMAP = {
    " " => :space,
    "h" => :left,
    "j" => :down,
    "k" => :up,
    "l" => :right,
    "w" => :up,
    "a" => :left,
    "s" => :down,
    "d" => :right,
    "\t" => :tab,
    "\r" => :return,
    "\n" => :newline,
    "\e" => :escape,
    "\e[A" => :up,
    "\e[B" => :down,
    "\e[C" => :right,
    "\e[D" => :left,
    "\177" => :backspace,
    "\004" => :delete,
    "\u0003" => :ctrl_c,
  }

  MOVES = {
    left: [0, -1],
    right: [0, 1],
    up: [-1, 0],
    down: [1, 0]
  }



  def get_input
    key = KEYMAP[read_char]
    handle_key(key)
  end

  def handle_key(key)
    case key
    when :ctrl_c
      exit 0
    when :return, :space
      @cursor
    when :left, :right, :down, :up
      update_pos(MOVES[key])
      nil
    when :escape
      cancel if respond_to?(cancel)
      nil
    when :tab
      @incrementer += 1
      nil
    else
      puts key
    end
  end

  def get_promotion_input
    key = KEYMAP[read_char]
    handle_promotion_key(key)
  end

  def handle_promotion_key(key)
    case key
    when :ctrl_c
      exit 0
    when :return, :space
      @incrementer
    when :tab
      @incrementer += 1
      nil
    else
      nil
    end
  end

  def read_char
    STDIN.echo = false
    STDIN.raw!

    input = STDIN.getc.chr
    if input == "\e" then
      input << STDIN.read_nonblock(3) rescue nil
      input << STDIN.read_nonblock(2) rescue nil
    end

  ensure
    STDIN.echo = true
    STDIN.cooked!

    return input

  end

  def update_pos(translation)
    new_pos = [@cursor[0] + translation[0], @cursor[1] + translation[1]]
    @cursor = new_pos if @board.in_bounds?(new_pos)
  end
end
