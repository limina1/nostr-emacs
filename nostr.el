;; -*- lexical-binding:t -*-

(require 'websocket)
(require 'cl)

;; Set these variables to use the tool

(setq nostr-root "")
(setq nostr-python-path (concat nostr-root ""))
(setq nostr-sk-path (concat nostr-root ""))
(setq nostr-keys-python (concat nostr-root "nostr_keys.py"))


(defun nostr-get-sk ()
  "nsec1swfhcrsvmfw5actkgw5445k48lewpund60ff90mm5j3up0wat8pqfqced2"
  )
(defun nostr-get-hex() "83937c0e0cda5d4ee17643a95ad2d53ff2e0f26dd3d292bf7ba4a3c0bddd59c2")

(defvar nostr-get-npub () "npub1xaq0sg0cgp0vqdkcnqxyy45ad6hcq6m5xj2cuk92ppjnzspkjdtsnypqdt"
  )



(defadvice json-encode (around encode-nil-as-json-empty-object activate)
  (if (null object)
      (setq ad-return-value "[]")
    ad-do-it))


(defun nostr-compute-id (pk created_at kind content)
  (secure-hash 'sha256 (json-encode-list (list 0 pk created_at kind nil content)))
  )


(defun nostr-sign (message)
  (shell-command-to-string
   (format "python%s %s sign %s" nostr-python-path nostr-keys-python message)
   ))
(nostr-sign "test10")

(defun nostr-create-event (sk kind content)
  (let* ((pk (nostr-get-pk sk))
	 (created_at (time-convert (current-time) 'integer))
	 (id (nostr-compute-id pk created_at kind content))
	 (sig (nostr-sign id sk))
	 )
    (format "[\"EVENT\",%s]" (json-encode-alist `((id . ,id) (pubkey . ,pk) (created_at . ,created_at) (kind . ,kind) (tags . ()) (content . ,content) (sig . ,sig))))
    )
  )


(defun nostr-send-message (event)
  (setq nostr-socket
        (websocket-open "wss://nostr-pub.wellorder.net"
		        :on-message (lambda (_websocket frame)
                                      (nostr-write-to-buf (format "ws frame: %S" (websocket-frame-text frame))))
		        :on-close (lambda (_websocket) (message "WS Closed"))
		        :on-error (lambda (_websocket frame)
				    (nostr-write-to-buf (format "ERROR: %S" (websocket-frame-text frame)))))
        )
  (sleep-for 2)
  (websocket-send-text nostr-socket event)
  (websocket-close nostr-socket)
  ()
  )


(defun nostr-post (message)
  (interactive "s")
  (nostr-send-message (nostr-create-event (nostr-get-sk nostr-sk-path) 1 message))
  )

(defun nostr-update-metadata (sk name about picture)
  (let* ((pk (nostr-get-pk sk))
	 (created_at (time-convert (current-time) 'integer))
	 (content (format "%s" (json-encode-alist `((name . ,name) (about . ,about) (picture . ,picture)))))
	 (kind 0)
	 (id (nostr-compute-id pk created_at kind content))
	 (sig (nostr-sign id sk))
	 )
    (format "[\"EVENT\",%s]" (json-encode-alist `((id . ,id) (pubkey . ,pk) (created_at . ,created_at) (kind . ,kind) (tags . ()) (content . ,content) (sig . ,sig))))
    )
  )
