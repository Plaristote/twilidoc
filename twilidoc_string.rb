class String
  def pop_first
    self[1..size - 1]
  end

  def pop
    self[0...size - 1]
  end

  def first
    self[0]
  end

  def last
    self[size - 1]
  end

  def emplace str, it_begin, it_end
    str_beg = self[0...it_begin]
    str_end = self[it_end..self.size]
    str_beg + str + str_end
  end

end

