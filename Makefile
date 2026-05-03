.PHONY: test update-snapshots

test:
	vim -Nu NONE -n -es -S test.vim

update-snapshots:
	QUADAR_UPDATE_SNAPSHOTS=1 vim -Nu NONE -n -es -S test.vim
