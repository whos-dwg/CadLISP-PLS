;;; ============================================================
;;; PLSimplify_v1_6.lsp
;;; Command: PLS6
;;; Fix: removes dependency on NTHCDR for older AutoLISP versions.
;;; ============================================================

(vl-load-com)

(if (not *PLS6-MinDist*) (setq *PLS6-MinDist* 1.0))
(if (not *PLS6-LineTol*) (setq *PLS6-LineTol* 2.0))

(defun PLS6:PX (p) (car p))
(defun PLS6:PY (p) (cdr p))

(defun PLS6:LastItem (lst)
  (if lst
    (progn
      (while (cdr lst)
        (setq lst (cdr lst)))
      (car lst))
    nil)
)

(defun PLS6:Drop (lst n)
  ;; Equivalent to NTHCDR, implemented manually for compatibility.
  (while (and lst (> n 0))
    (setq lst (cdr lst)
          n   (1- n)))
  lst
)

(defun PLS6:Dist (a b / dx dy)
  (setq dx (- (PLS6:PX a) (PLS6:PX b))
        dy (- (PLS6:PY a) (PLS6:PY b)))
  (sqrt (+ (* dx dx) (* dy dy)))
)

(defun PLS6:PointSegDist (p a b / abx aby apx apy len2 u qx qy dx dy)
  (setq abx (- (PLS6:PX b) (PLS6:PX a))
        aby (- (PLS6:PY b) (PLS6:PY a))
        apx (- (PLS6:PX p) (PLS6:PX a))
        apy (- (PLS6:PY p) (PLS6:PY a))
        len2 (+ (* abx abx) (* aby aby)))

  (if (< len2 1e-20)
    (PLS6:Dist p a)
    (progn
      (setq u (/ (+ (* apx abx) (* apy aby)) len2))
      (cond
        ((< u 0.0) (setq u 0.0))
        ((> u 1.0) (setq u 1.0)))
      (setq qx (+ (PLS6:PX a) (* u abx))
            qy (+ (PLS6:PY a) (* u aby))
            dx (- (PLS6:PX p) qx)
            dy (- (PLS6:PY p) qy))
      (sqrt (+ (* dx dx) (* dy dy)))
    )
  )
)

(defun PLS6:GetPts (en / ed item pts)
  (setq ed (entget en)
        pts nil)
  (foreach item ed
    (if (= (car item) 10)
      (setq pts
        (cons
          (cons (float (cadr item))
                (float (caddr item)))
          pts))))
  (reverse pts)
)

(defun PLS6:ButLast (lst / out)
  (setq out nil)
  (while (and lst (cdr lst))
    (setq out (cons (car lst) out)
          lst (cdr lst)))
  (reverse out)
)

(defun PLS6:Take (lst n / out)
  (setq out nil)
  (while (and lst (> n 0))
    (setq out (cons (car lst) out)
          lst (cdr lst)
          n   (1- n)))
  (reverse out)
)

(defun PLS6:RemoveClose (pts tol / out lastp endpoint p)
  (if (<= (length pts) 2)
    pts
    (progn
      (setq out      (list (car pts))
            lastp    (car pts)
            endpoint (PLS6:LastItem pts))

      (foreach p (cdr (PLS6:ButLast pts))
        (if (>= (PLS6:Dist p lastp) tol)
          (progn
            (setq out (append out (list p)))
            (setq lastp p))))

      (if (< (PLS6:Dist (PLS6:LastItem out) endpoint) tol)
        (if (> (length out) 1)
          (append (PLS6:ButLast out) (list endpoint))
          (list (car out) endpoint))
        (append out (list endpoint)))
    )
  )
)

(defun PLS6:RDP (pts tol / first lastpt maxd maxi idx p d left right mids)
  (if (<= (length pts) 2)
    pts
    (progn
      (setq first  (car pts)
            lastpt (PLS6:LastItem pts)
            maxd   -1.0
            maxi   nil
            idx    1
            mids   (cdr (PLS6:ButLast pts)))

      (foreach p mids
        (setq d (PLS6:PointSegDist p first lastpt))
        (if (> d maxd)
          (setq maxd d
                maxi idx))
        (setq idx (1+ idx)))

      (if (and maxi (> maxd tol))
        (progn
          (setq left  (PLS6:Take pts (1+ maxi))
                right (PLS6:Drop pts maxi))
          (append
            (PLS6:ButLast (PLS6:RDP left tol))
            (PLS6:RDP right tol)))
        (list first lastpt))
    )
  )
)

(defun PLS6:MaxDeviation (pts / first lastpt maxd p d)
  (if (<= (length pts) 2)
    0.0
    (progn
      (setq first  (car pts)
            lastpt (PLS6:LastItem pts)
            maxd   0.0)
      (foreach p (cdr (PLS6:ButLast pts))
        (setq d (PLS6:PointSegDist p first lastpt))
        (if (> d maxd)
          (setq maxd d)))
      maxd))
)

(defun PLS6:HasArc (en / item hit)
  (setq hit nil)
  (foreach item (entget en)
    (if (and (= (car item) 42)
             (numberp (cdr item))
             (> (abs (cdr item)) 1e-12))
      (setq hit T)))
  hit
)

(defun PLS6:MakeNew (old pts / ed data code item new)
  (setq ed (entget old)
        data (list '(0 . "LWPOLYLINE")
                   '(100 . "AcDbEntity")))

  (foreach code '(8 6 62 48 370 420 440)
    (if (assoc code ed)
      (setq data (append data (list (assoc code ed))))))

  (setq data
    (append data
      (list '(100 . "AcDbPolyline")
            (cons 90 (length pts))
            (cons 70 0))))

  (foreach code '(43 38 39 210)
    (if (assoc code ed)
      (setq data (append data (list (assoc code ed))))))

  (foreach item pts
    (setq data
      (append data
        (list
          (list 10 (PLS6:PX item) (PLS6:PY item))))))

  (setq new (entmakex data))

  (if new
    (progn
      (entdel old)
      new)
    nil)
)

(defun c:PLS (/ *error* doc sel en ed pts minD tol p1 p2
                  before after maxdev new)

  (vl-load-com)
  (setq doc (vla-get-ActiveDocument (vlax-get-acad-object)))

  (defun *error* (msg)
    (vl-catch-all-apply 'vla-EndUndoMark (list doc))
    (if (and msg
             (/= msg "Function cancelled")
             (/= msg "quit / exit abort"))
      (princ (strcat "\nPLS6 Error: " msg)))
    (princ))

  (initget 6)
  (setq minD
    (getdist
      (strcat "\nMinimum vertex distance <"
              (rtos *PLS6-MinDist* 2 3) ">: ")))
  (if minD
    (setq *PLS6-MinDist* minD))

  (initget 6)
  (setq tol
    (getdist
      (strcat "\nMaximum line deviation <"
              (rtos *PLS6-LineTol* 2 3) ">: ")))
  (if tol
    (setq *PLS6-LineTol* tol))

  (prompt "\nSelect ONE LWPOLYLINE: ")
  (setq sel (entsel))

  (if sel
    (progn
      (setq en (car sel)
            ed (entget en))

      (cond
        ((/= (cdr (assoc 0 ed)) "LWPOLYLINE")
         (princ "\nSelected object is not an LWPOLYLINE."))

        ((= 1 (logand 1 (cdr (assoc 70 ed))))
         (princ "\nSkipped: closed polyline."))

        ((PLS6:HasArc en)
         (princ "\nSkipped: polyline contains arc/bulge segments."))

        (T
         (setq pts    (PLS6:GetPts en)
               before (length pts))

         (princ
           (strcat
             "\nDetected vertices: " (itoa before)
             "\nOverall max deviation from endpoint line: "
             (rtos (PLS6:MaxDeviation pts) 2 4)))

         (if (< before 3)
           (princ "\nNothing to simplify.")
           (progn
             (setq p1    (PLS6:RemoveClose pts *PLS6-MinDist*)
                   p2    (PLS6:RDP p1 *PLS6-LineTol*)
                   after (length p2))

             (if (< after before)
               (progn
                 (vla-StartUndoMark doc)
                 (setq new (PLS6:MakeNew en p2))
                 (vla-EndUndoMark doc)

                 (if new
                   (princ
                     (strcat
                       "\nSimplified: "
                       (itoa before) " -> " (itoa after)
                       " vertices."))
                   (princ
                     "\nCould not rebuild polyline; original left intact.")))
               (princ
                 (strcat
                   "\nNo change. Vertices remain: "
                   (itoa before)))))))))
    (princ "\nNothing selected."))

  (princ)
)

(princ "\nPLSimplify v1.6 loaded. Use command: PLS6")
(princ)
