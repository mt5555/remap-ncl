load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"


begin
  print("map file checker v1. M. Taylor 2015-09-09")
  print("One should verify that:")
  print("- sum of area weights is close to physical area (if nonzero weights)")
  print("- mapping weights are in [0,1] for monotone maps")
  print("- mapping weights are near [0,1] for other maps")
  print("- frac_b(rowsum) = 1 (correctly maps constant function)")
  print("-   for regional (a<b) expect min<1, max=1")
  print("- frac_a (area_b weighted column sum / area_a) ~ 1 for conservation)")
  print("    for grids a<=b, expect min/max ~1")
  print("    for regional (a>b): expect min<1, max=1")
  print("- no missing target points (unless source grid has holes)")

  if (isvar("map")) then    
    mapname = map
  else
    mapname = "map_181x360_to_conusx4v1np4qw_bilin.nc"
  end if
  f = addfile(mapname,"r")

  n_s = dimsizes(f->col)
  n_b = dimsizes(f->area_b)
  n_a = dimsizes(f->area_a)
  print("sparse matrix size n_s="+n_s) 
  
  S = f->S
  row = f->row
  col = f->col

  print("n_a="+n_a+"  col index (1-based) min/max= "+min(col)+" "+max(col))
  print("n_b="+n_b+"  row index (1-based) min/max= "+min(row)+" "+max(row))
  ; row/col data is 1-based
  if (min(row) .lt. 1 ) then
    print("error: row index < 1")
    ibad=ind(col.lt.1)
    print("row(ibad)="+row(ibad)+" col(ibad)="+col(ibad)+" w="+S(ibad))
  end if
  if (max(row) .gt. n_b ) then
    print("error: row index > n_b")
    ibad=ind(col.gt.n_b)
    print("row(ibad)="+row(ibad)+" col(ibad)="+col(ibad)+" w="+S(ibad))
  end if
  if (min(col) .lt. 1 ) then
    print("error: col index < 1")
    ibad=ind(col.lt.1)
    print("row(ibad)="+row(ibad)+" col(ibad)="+col(ibad)+" w="+S(ibad))
  end if
  if (max(col) .gt. n_a ) then
    print("error: col index > n_a")
    ibad=ind(col.gt.n_a)
    print("row(ibad)="+row(ibad)+" col(ibad)="+col(ibad)+" w="+S(ibad))
  end if



  area_a = f->area_a
  area_b = f->area_b
  if (isfilevar(f,"mask_a")) then
     mask_a = f->mask_a
     mask_b = f->mask_b
  else
     mask_a = new(n_a,integer)
     mask_b = new(n_b,integer)
     mask_a = 1
     mask_b = 1
  end if

  pi=4*atan(1d0)
  print("grid a mask min/max: "+min(mask_a)+" "+max(mask_a))
  print("grid b mask min/max: "+min(mask_b)+" "+max(mask_b))
  print("area_a min/max= "+min(area_a)+" "+max(area_a))
  print("area_b min/max= "+min(area_b)+" "+max(area_b))
  print("frac_a min/max= "+min(f->frac_a)+" "+max(f->frac_a))
  print("frac_b min/max= "+min(f->frac_b)+" "+max(f->frac_b))
  print("sum area_a weights / 4pi: "+ (sum(area_a) / (4*pi)) )
  print("sum area_b weights / 4pi: "+ (sum(area_b) / (4*pi)) ) 
  print("mapping weights:  min/max= "+min(S)+" "+max(S))

  ibadlist = ind(S .eq. max(S))
  ibad=ibadlist(0);
  print("max weight index: "+ibad)
  rbad=row(ibad)-1
  cbad=col(ibad)-1
  print("row="+rbad+" frac_b(row)="+f->frac_b(rbad))
  print("col="+cbad+" frac_a(col)="+f->frac_a(cbad))
  

;  if (sum(area_a) .lt. .1) then
;    print("area_a values are bad. setting to 1")
;    area_a = 1
;  end if
;  if (sum(area_b) .lt. .1) then
;    print("area_b values are bad. setting to 1")
;    area_b = 1
;  end if

  colsum=new(n_a,double)
  colnum=new(n_a,integer)
  colsum=0
  colnum=0
 
  
  rowsum=new(n_b,double)
  rownum=new(n_b,integer)
  rowsum=0
  rownum=0

; col is the data_a  index  ( gx1v5 grid )
; row is the data_b index   ( homme grid )
  print("examing weights...")
  do i=0,n_s-1
;  do i=23671483-1,23671488+1
    ic=col(i)-1  ; convert to 0-based index
    ir=row(i)-1  ; convert to 0-based index
    if (mod(i,1000000).eq.0) then
       print(i+"/"+n_s)
    end if
    if (ir .eq. rbad) then
       print("i="+i+" row="+rbad+" col="+ic+" S(i)="+S(i))
       print("   frac_a(col),frac_b(row)="+f->frac_a(ic)+" "+f->frac_b(ir))
       print("   area_a(col),area_b(row)="+area_a(ic)+" "+area_b(ir))
    end if
    colsum(ic)=colsum(ic)+S(i)*area_b(ir)
    colnum(ic)=colnum(ic)+1
    rowsum(ir)=rowsum(ir)+S(i)
    rownum(ir)=rownum(ir)+1

  end do

  ; put missing values where mask_b /= 1
  ;rowsum_mask=mask(rowsum,mask_b,1)  ; only look at rows where mask_b=1
  rowsum_mask=mask(rowsum,((rownum.gt.0) .and. (mask_b.eq.1)),True)  ; only look at rows where rownum>0
  
  print("frac_b(row sum) min/max = "+min(rowsum_mask)+" "+max(rowsum_mask))
  print("frac_a(area_b weighted col sums / area_a)")
  print("   min/max = "+min(colsum/area_a)+" "+max(colsum/area_a))



; compute row and col histogram
  rcount = new(max(rownum)+1,integer)
  ccount = new(max(colnum)+1,integer)
  rcount = 0
  ccount = 0

  do ic=0,n_a-1
    ccount(colnum(ic)) = ccount(colnum(ic)) +1
  end do
  do ir=0,n_b-1
    rcount(rownum(ir)) = rcount(rownum(ir)) +1
  end do
 
  print("Histogram of non-zero row/column entries")
  print("column 1: number of nonzero entries (histogram bin)")
  print("column 2: number of columns with that many nonzero entries")
  print("column 3: number of rows with that many nonzero entries")

  imax=30
  do i=0,imax
    if ( (i .le. max(colnum)) .and. (i .le. max(rownum) ) ) then
       print(i + "   " + ccount(i)+ "   " + rcount(i))
    else 
       if ( i .le. max(colnum)) then
          print(i + "   " + ccount(i)+ "   " + 0)
       else 
          if ( i .le. max(rownum)) then
            print(i + "   " + 0 + "   " + rcount(i))
          end if
       end if
    end if
  end do     
  if ((imax.lt.max(colnum)) .and. (imax.lt.max(rownum)) )  then
    print(i + "+  " + sum(ccount(imax+1:)) + "   " + sum(rcount(imax+1:))  )
  else
    if (imax.lt.max(rownum)) then
    print(i + "+  " + 0 + "   " + sum(rcount(imax+1:))  )
    else
      if (imax.lt.max(colnum)) then
    print(i + "+  " + sum(ccount(imax+1:)) + "   " + 0 )
      end if
    end if
  end if

  print("Number of ignored source points (empty columns): "+ccount(0))
  print("Number of missing target points (empty rows):    "+rcount(0))



  print("checking for dups, sorting...")
  hash = new( n_s, double )
  hash = col
  hash= hash + row*n_b 
  index1d=dim_pqsort(hash,1)
  row2=row(index1d)
  col2=col(index1d)
  S=f->S
  print("searching...")
  ndups=0
  i0=0
  do i=1,n_s-1
    if ( (col2(i) .eq. col2(i0)) .and. (row2(i) .eq. row2(i0))) then
        ndups=ndups+1
        ; dont increment i0
    else
        i0=i 
    end if
  end do
  print("number of dups="+ndups)

  
end
    


