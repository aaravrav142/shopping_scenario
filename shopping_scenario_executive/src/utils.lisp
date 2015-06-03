;;; Copyright (c) 2015, Jan Winkler <winkler@cs.uni-bremen.de>
;;; All rights reserved.
;;;
;;; Redistribution and use in source and binary forms, with or without
;;; modification, are permitted provided that the following conditions are met:
;;;
;;; * Redistributions of source code must retain the above copyright
;;; notice, this list of conditions and the following disclaimer.
;;; * Redistributions in binary form must reproduce the above copyright
;;; notice, this list of conditions and the following disclaimer in the
;;; documentation and/or other materials provided with the distribution.
;;; * Neither the name of the Institute for Artificial Intelligence/
;;; Universitaet Bremen nor the names of its contributors may be used to 
;;; endorse or promote products derived from this software without specific 
;;; prior written permission.
;;;
;;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
;;; AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
;;; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
;;; ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
;;; LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
;;; CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
;;; SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
;;; INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
;;; CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
;;; ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
;;; POSSIBILITY OF SUCH DAMAGE.

(in-package :shopping-scenario-executive)

;;;
;;; Infrastructure Utilities
;;;

(defmacro with-process-modules (&body body)
  "Implicitly runs process modules necessary for operating the PR2 robot. The started (and after finishing the body code also automatically evaporated) process modules are:

 - pr2-manipulation-process-module
 - pr2-navigation-process-module
 - point-head-process-module
 - robosherlock-process-module"
  `(cpm:with-process-modules-running
       (pr2-manipulation-process-module:pr2-manipulation-process-module
        pr2-navigation-process-module:pr2-navigation-process-module
        point-head-process-module:point-head-process-module
        robosherlock-process-module:robosherlock-process-module)
     ,@body))

(defmacro with-simulation-process-modules (&body body)
  "Implicitly runs process modules necessary for operating the PR2 robot in a Gazebo simulation. The started (and after finishing the body code also automatically evaporated) process modules are:

 - pr2-manipulation-process-module
 - pr2-navigation-process-module
 - point-head-process-module
 - gazebo-perception-process-module"
  `(cpm:with-process-modules-running
       (pr2-manipulation-process-module:pr2-manipulation-process-module
        pr2-navigation-process-module:pr2-navigation-process-module
        point-head-process-module:point-head-process-module
        gazebo-perception-process-module:gazebo-perception-process-module)
     ,@body))

(defun get-robot-pose (&optional (frame-id "/base_link"))
  (cl-tf2:ensure-pose-stamped-transformed
   *tf2*
   (tf:make-pose-stamped
    frame-id
    0.0
    (tf:make-identity-vector)
    (tf:make-identity-rotation))
   "/map" :use-current-ros-time t))

(defun move-arms-up (&key allowed-collision-objects side ignore-collisions)
  (when (or (eql side :left) (not side))
    (pr2-manip-pm::execute-move-arm-pose
     :left
     (tf:make-pose-stamped
      "base_link" (roslisp:ros-time)
      (tf:make-3d-vector 0.3 0.5 0.8);1.3
      (tf:euler->quaternion :ax 0));pi))
     :ignore-collisions ignore-collisions
     :allowed-collision-objects allowed-collision-objects))
  (when (or (eql side :right) (not side))
    (pr2-manip-pm::execute-move-arm-pose
     :right
     (tf:make-pose-stamped
      "base_link" (roslisp:ros-time)
      (tf:make-3d-vector 0.3 -0.5 0.8);1.3
      (tf:euler->quaternion :ax 0))
     :ignore-collisions ignore-collisions
     :allowed-collision-objects allowed-collision-objects)))

(defun init-belief-state ()
  (let* ((urdf-robot
           (cl-urdf:parse-urdf
            (roslisp:get-param "robot_description_lowres")))
         (urdf-rack
           (cl-urdf:parse-urdf
            (roslisp:get-param "shopping_rack_description")))
         (urdf-area
           (cl-urdf:parse-urdf
            (roslisp:get-param "shopping_area_description")))
         (rack-rot-quaternion (tf:euler->quaternion :az -1.57))
         (rack-rot `(,(tf:x rack-rot-quaternion)
                     ,(tf:y rack-rot-quaternion)
                     ,(tf:z rack-rot-quaternion)
                     ,(tf:w rack-rot-quaternion)))
         (rack-trans `(1.275 0.214 0))
         (area-rot-quaternion (tf:euler->quaternion :az -1.57))
         (area-rot `(,(tf:x area-rot-quaternion)
                     ,(tf:y area-rot-quaternion)
                     ,(tf:z area-rot-quaternion)
                     ,(tf:w area-rot-quaternion)))
         (area-trans `(2.720 0.295 0)))
    (force-ll
     (crs:prolog
      `(and (btr:clear-bullet-world)
            (btr:bullet-world ?w)
            (btr:assert (btr:object
                         ?w btr:static-plane floor
                         ((0 0 0) (0 0 0 1))
                         :normal (0 0 1) :constant 0))
            (btr:debug-window ?w)
            (btr:robot ?robot)
            (assert (btr:object
                     ?w btr:urdf ?robot ,(get-robot-pose)
                     :urdf ,urdf-robot))
            (assert (btr:object
                     ?w btr:semantic-map sem-map-rack
                     (,rack-trans ,rack-rot)
                     :urdf ,urdf-rack))
            (assert (btr:object
                     ?w btr:semantic-map sem-map-area
                     (,area-trans ,area-rot)
                     :urdf ,urdf-area)))))))

(defun make-target-arrangement (&key hints)
  )
