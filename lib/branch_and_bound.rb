# General algorithm:
# * keep a matrix of costs
# * bounds are set by minimum elements of each row/column
# * branch on including/excluding a node
#   * include: delete the row+column and exclude cycle-creating edge
#   * exclude: set the entry to infinity
#
# Resources on this algorithm:
# https://people.eecs.berkeley.edu/~demmel/cs267/assignment4.html
# This page in turn cites "Combinatorial Algorithms: Theory and Practice"
#   by Reingold, Nievergelt and Deo.
#
# J. D. C. Little, K. G. Murty, D. W. Sweeney, and C. Karel.
# An algorithm for the traveling salesman problem.
# MIT Operations Research, 11:972–989, 1963.
# http://dspace.mit.edu/bitstream/handle/1721.1/46828/algorithmfortrav00litt.pdf
#
# The method described above seems to be an improvement compared to:
# * http://lcm.csa.iisc.ernet.in/dsa/node187.html
# * http://www.jot.fm/issues/issue_2003_03/column7.pdf
# since it makes smart choices about which edge to consider first.
#
# Thus, it is the method used below.
module BranchAndBound
  module_function

  def edge_to_remove(forward, reverse, left, right)
    right = forward[right] while forward.has_key?(right)
    left = reverse[left] while reverse.has_key?(left)
    [right, left]
  end

  def row_reduce!(matrix)
    matrix.sum { |row|
      m = row.min
      row.map! { |x| x - m }
      m
    }
  end

  def col_reduce!(matrix)
    cols = matrix.transpose
    cols.map.with_index { |col, i|
      m = col.min
      matrix.each { |row| row[i] -= m }
      m
    }.sum
  end

  def search(stat, matrix, edges, rev_edges, bound)
    # We should never get here if bound > stat[:best],
    # so it's safe to set it unconditionally.
    return (stat[:best] = bound) if matrix.size - edges.size == 1

    mins_row = Array.new(matrix.size, 1.0 / 0.0)
    seconds_row = Array.new(matrix.size, 1.0 / 0.0)
    mins_col = Array.new(matrix.size, 1.0 / 0.0)
    seconds_col = Array.new(matrix.size, 1.0 / 0.0)

    matrix.each_with_index { |row, r|
      row.each_with_index { |val, c|
        if val < mins_row[r]
          seconds_row[r] = mins_row[r]
          mins_row[r] = val
        elsif val < seconds_row[r]
          seconds_row[r] = val
        end

        if val < mins_col[c]
          seconds_col[c] = mins_col[c]
          mins_col[c] = val
        elsif val < seconds_col[c]
          seconds_col[c] = val
        end
      }
    }

    best_bound_increase = -1
    best_col = nil
    best_row = nil

    matrix.each_with_index { |row, i|
      row.each_with_index { |cell, j|
        next if cell != 0
        bound_increase = seconds_row[i] + seconds_col[j]
        if best_bound_increase < bound_increase
          best_bound_increase = bound_increase
          best_row = i
          best_col = j
        end
      }
    }

    edges[best_row] = best_col
    rev_edges[best_col] = best_row

    rows_losing_zeroes = []
    cols_losing_zeroes = []
    left_block = nil
    left_restore = nil

    # Search left: Include the edge
    # (delete its row/column, exclude edge that would make cycle).
    if matrix.size - edges.size > 2
      vdel, udel = edge_to_remove(edges, rev_edges, best_row, best_col)
      left_blocked_val = matrix[vdel][udel]
      if left_blocked_val == 0
        rows_losing_zeroes << vdel
        cols_losing_zeroes << udel
      end
      left_block = ->(left_matrix) { left_matrix[vdel][udel] = 1.0 / 0.0 }
      left_restore = ->(left_matrix) { left_matrix[vdel][udel] = left_blocked_val }
    end
    matrix.each_with_index { |row, r|
      rows_losing_zeroes << r if row[best_col] == 0
    }

    best = 1.0 / 0.0

    rows_losing_zeroes.uniq!
    rows_losing_zeroes.delete(best_row)

    # We can't add the column seconds yet,
    # since they might change on row reduction.
    # However, if the row reduction alone would bring us over,
    # we don't need to bother doing it or the column reduction.
    left_bound = bound + rows_losing_zeroes.sum { |r| seconds_row[r] }

    if left_bound < stat[:best]
      deleted_row = matrix[best_row].dup
      deleted_row.each_with_index { |d, c| cols_losing_zeroes << c if d == 0 }
      deleted_col = matrix.map { |row| row[best_col]  }

      matrix[best_row].fill(1.0 / 0.0)
      matrix.each { |row| row[best_col] = 1.0 / 0.0 }
      left_block[matrix] if left_block

      left_seconds_col = seconds_col.dup

      # Instead of using row_reduce! and col_reduce! here,
      # we only act on the rows/columns that lost zeroes, for efficiency.
      rows_losing_zeroes.each { |r|
        second = seconds_row[r]
        next if second == 0
        matrix[r].map!.with_index { |x, c|
          (x - second).tap { |newval|
            # Did second-min change?
            left_seconds_col[c] = [left_seconds_col[c], newval].min
          }
        }
      }

      cols_losing_zeroes.uniq!
      cols_losing_zeroes.delete(best_col)

      left_bound += cols_losing_zeroes.sum { |c| left_seconds_col[c] }

      if left_bound < stat[:best]
        cols_losing_zeroes.each { |c|
          second = left_seconds_col[c]
          next if second == 0
          matrix.each { |row| row[c] -= second }
        }

        left = search(
          stat,
          matrix,
          edges, rev_edges,
          left_bound,
        )
        best = [best, left].min

        cols_losing_zeroes.each { |c|
          second = left_seconds_col[c]
          next if second == 0
          matrix.each { |row| row[c] += second }
        }
      end

      rows_losing_zeroes.each { |r|
        second = seconds_row[r]
        next if second == 0
        matrix[r].map! { |x| x + second }
      }

      left_restore[matrix] if left_restore
      matrix.each_with_index { |row, i| row[best_col] = deleted_col[i] }
      matrix[best_row] = deleted_row
    end

    edges.delete(best_row)
    rev_edges.delete(best_col)

    right_bound = bound + best_bound_increase
    if right_bound < stat[:best]
      saved = matrix[best_row][best_col]
      matrix[best_row][best_col] = 1.0 / 0.0
      # Instead of using row_reduce! and col_reduce! here,
      # we only act on the row/column that lost its zero, for efficiency.
      row_reduce = seconds_row[best_row]
      matrix[best_row].map! { |x| x - row_reduce } if row_reduce > 0
      col_reduce = seconds_col[best_col]
      matrix.each { |row| row[best_col] -= col_reduce } if col_reduce > 0
      # We can reuse everything; left paths copied everything already,
      # and nothing comes after a right path.
      right = search(
        stat,
        matrix,
        edges, rev_edges,
        right_bound,
      )
      best = [best, right].min

      # Restore.
      matrix[best_row].map! { |x| x + row_reduce } if row_reduce > 0
      matrix.each { |row| row[best_col] += col_reduce } if col_reduce > 0
      matrix[best_row][best_col] = saved
    end

    best
  end

  def best_cycle(dists)
    pos = dists.each_key.with_index.to_a
    matrix = pos.map { |u, i|
      pos.map { |v, j| i == j ? 1.0 / 0.0 : dists[u][v] }
    }

    # In case the distance matrix isn't symmetric:
    # See which way gives a *larger* lower bound (larger bounds are tighter)
    mt = matrix.transpose
    bound = row_reduce!(matrix) + col_reduce!(matrix)
    boundt = row_reduce!(mt) + col_reduce!(mt)

    search(
      {best: 1.0 / 0.0},
      boundt > bound ? mt : matrix,
      {}, {},
      [boundt, bound].max,
    )
  end
end
