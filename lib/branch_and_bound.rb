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

  PRINT = !ENV.has_key?('TRAVIS')

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

  def pmat(mat)
    puts mat.map { |row|
      row.map { |c| c == 1.0 / 0.0 ? 'inf' : ('%3d' % c) }.join(' ')
    } if PRINT
  end

  def search(stat, path, matrix, edges, rev_edges, bound, row_indices, col_indices)
    # We should never get here if bound > stat[:best],
    # so it's safe to set it unconditionally.
    return (stat[:best] = bound) if matrix.size == 1

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

    u = row_indices[best_row]
    v = col_indices[best_col]
    edges[u] = v
    rev_edges[v] = u

    rows_losing_zeroes = []
    cols_losing_zeroes = []
    left_block = nil

    # Search left: Include the edge
    # (delete its row/column, exclude edge that would make cycle).
    if matrix.size > 2
      vdel, udel = edge_to_remove(edges, rev_edges, u, v)
      vv = row_indices.index(vdel)
      uu = col_indices.index(udel)
      if matrix[vv][uu] == 0
        rows_losing_zeroes << vv
        cols_losing_zeroes << uu
      end
      left_block = ->(left_matrix) { left_matrix[vv][uu] = 1.0 / 0.0 }
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
    right_bound = bound + best_bound_increase

    pi = ->(a) { a == 1.0 / 0.0 ? 'inf' : a.to_s }
    p = ->(a, b, c) { puts ("%-28s [%d, %d] \e[%sm%3s\e[0m <- %3s -> \e[%sm%3s\e[0m (best %3s)" % [
      ('  ' * path.size) + ('%-5s %-4s' % [a, b]),
      u, v,
      b == 'incl' ? "1;3#{a == 'open' ? 2 : 1}" : 0,
      pi[left_bound],
      pi[bound],
      b == 'excl' ? "1;3#{a == 'open' ? 2 : 1}" : 0,
      pi[right_bound],
      pi[stat[:best]],
    ]) if PRINT }

    if left_bound < stat[:best]
      left_matrix = matrix.map(&:dup)
      left_block[left_matrix] if left_block
      deleted_row = left_matrix.delete_at(best_row)
      deleted_row.each_with_index { |d, c| cols_losing_zeroes << c if d == 0 }
      left_matrix.each { |row| row.delete_at(best_col) }

      left_seconds_col = seconds_col.dup

      # Instead of using row_reduce! and col_reduce! here,
      # we only act on the rows/columns that lost zeroes, for efficiency.
      rows_losing_zeroes.each { |r|
        second = seconds_row[r]
        next if second == 0
        left_matrix[r >= best_row ? r - 1 : r].map!.with_index { |x, c|
          (x - second).tap { |newval|
            # Did second-min change?
            real_c = c >= best_col ? c + 1 : c
            left_seconds_col[real_c] = [left_seconds_col[real_c], newval].min
          }
        }
      }

      cols_losing_zeroes.uniq!
      cols_losing_zeroes.delete(best_col)

      left_bound += cols_losing_zeroes.sum { |c| left_seconds_col[c] }

      if left_bound < stat[:best]
        p['open', 'incl', left_bound]

        cols_losing_zeroes.each { |c|
          second = left_seconds_col[c]
          next if second == 0
          real_c = c >= best_col ? c - 1 : c
          left_matrix.each { |row| row[real_c] -= second }
        }

        left = search(
          stat,
          path + [:l],
          left_matrix,
          edges, rev_edges,
          left_bound,
          row_indices.take(best_row) + row_indices.drop(best_row + 1),
          col_indices.take(best_col) + col_indices.drop(best_col + 1),
        )
        best = [best, left].min
      else
        p['prune', 'incl', left_bound]
      end
    else
      # The exclamation mark tells me it's a special prune.
      p['prun!', 'incl', left_bound]
    end

    edges.delete(u)
    rev_edges.delete(v)

    if right_bound < stat[:best]
      p['open', 'excl', right_bound]
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
        path << :r,
        matrix,
        edges, rev_edges,
        right_bound,
        row_indices, col_indices,
      )
      best = [best, right].min
    else
      p['prune', 'excl', right_bound]
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
    pmat(boundt > bound ? mt : matrix)

    search(
      {best: 1.0 / 0.0},
      [],
      boundt > bound ? mt : matrix,
      {}, {},
      [boundt, bound].max,
      *2.times.map { (0...matrix.size).to_a },
    )
  end
end
