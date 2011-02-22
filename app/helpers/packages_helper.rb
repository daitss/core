module PackagesHelper

  SI_UNITS = {
    :unit => '#',
    :ten => 'da',
    :hundred => 'h',
    :thousand => 'k',
    :million => 'M',
    :billion => 'G',
    :trillion => 'T',
    :quadrillion => 'P'
  }

  def number_in_si n

    if n >= 1000
      number_to_human n, :precision => 2, :units => SI_UNITS
    else
      n
    end

  end

end
