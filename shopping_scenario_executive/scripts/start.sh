#!/usr/bin/env sh
"true";exec /usr/bin/env /usr/bin/sbcl --noinform --end-runtime-options --noprint --no-userinit --disable-debugger --script "$0" "$@"


(REQUIRE :ASDF)

(labels ((get-roslisp-path ()
           ;; calls rospack to find path to roslisp
           (let ((rospack-process
                   (run-program "rospack" '("find" "roslisp")
                                :search t
                                :output :stream)))
             (when rospack-process
               (unwind-protect
                    (with-open-stream (o (process-output rospack-process))
                      (concatenate 'string (car (loop
                                                  for line := (read-line o nil nil)
                                                  while line
                                                  collect line)) "/load-manifest/"))
                 (process-close rospack-process)))))
         (load-ros-lookup ()
           ;; make sure roslisp is in asdf central registry
           (PUSH (get-roslisp-path) ASDF:*CENTRAL-REGISTRY*)
           ;; load ros-load-manifest, defining e.g. "ros-load:load-system"
           (ASDF:OPERATE 'ASDF:LOAD-OP :ROS-LOAD-MANIFEST :VERBOSE NIL)))
  (load-ros-lookup))

(PUSH :ROSLISP-STANDALONE-EXECUTABLE *FEATURES*)

(ros-load:load-system "roslisp" "roslisp")


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;          Here, the actual executive code begins.          ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;; Make sure the shopping scenario package is loaded
(roslisp:ros-info (shopping-aux) "Loading Shopping Scenario.")
(ros-load:load-system "shopping_scenario_executive" "shopping-scenario-executive")
(roslisp:ros-info (shopping-aux) "Shopping Scenario loaded.")

;; Start the scenario
(shopping:start-scenario-external)
