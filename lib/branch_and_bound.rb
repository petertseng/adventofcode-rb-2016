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

  def search(stat, matrix, edges, rev_edges, bound, row_indices, col_indices)
    # We should never get here if bound > stat[:best],
    # so it's safe to set it unconditionally.
    return (stat[:best] = bound) if matrix.size == 1

    seconds_row = matrix.map { |row| row.sort[1] }
    seconds_col = matrix.transpose.map { |col| col.sort[1] }

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

    # Search left: Include the edge
    # (delete its row/column, exclude edge that would make cycle).
    left_matrix = matrix.map(&:dup)
    if matrix.size > 2
      vdel, udel = edge_to_remove(edges, rev_edges, u, v)
      vv = row_indices.index(vdel)
      uu = col_indices.index(udel)
      left_matrix[vv][uu] = 1.0 / 0.0
    end
    left_matrix.delete_at(best_row)
    left_matrix.each { |row| row.delete_at(best_col) }

    left_bound = bound + row_reduce!(left_matrix) + col_reduce!(left_matrix)

    best = 1.0 / 0.0

    if left_bound < stat[:best]
      left = search(
        stat,
        left_matrix,
        edges, rev_edges,
        left_bound,
        row_indices.take(best_row) + row_indices.drop(best_row + 1),
        col_indices.take(best_col) + col_indices.drop(best_col + 1),
      )
      best = [best, left].min
    end

    edges.delete(u)
    rev_edges.delete(v)

    right_bound = bound + best_bound_increase
    if right_bound < stat[:best]
      matrix[best_row][best_col] = 1.0 / 0.0
      # We do expect that bound + row_reduce! + col_reduce! == right_bound
      # We don't need to check this.
      row_reduce!(matrix)
      col_reduce!(matrix)
      # We can reuse everything; left paths copied everything already,
      # and nothing comes after a right path.
      right = search(
        stat,
        matrix,
        edges, rev_edges,
        right_bound,
        row_indices, col_indices,
      )
      best = [best, right].min
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
      *2.times.map { (0...matrix.size).to_a },
    )
  end
end
