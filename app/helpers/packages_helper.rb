module PackagesHelper

  SI_UNITS = {
    #:unit => '',
    #:ten => '',
    #:hundred => '',
    :thousand => 'k',
    :million => 'M',
    :billion => 'G',
    :trillion => 'T',
    :quadrillion => 'P'
  }

  def number_in_si n
    number_to_human n, :precision => 2, :units => SI_UNITS
  end

end
