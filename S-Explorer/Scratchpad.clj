Get all "names" from the current environment:

(defn distinct-sorted [coll]
  (when-let [[f & r] (seq coll)] 
    (if (= f (first r)) 
      (distinct-sorted r)
      (cons f (distinct-sorted r)))))

=> (time (distinct-sorted (sort (flatten (map #(keys (ns-publics %)) (all-ns))))))


or  the slower

=> (time (sort (distinct (flatten (map #(keys (ns-publics %)) (all-ns))))))

