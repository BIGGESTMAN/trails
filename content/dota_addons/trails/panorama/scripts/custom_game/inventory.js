"use strict";

var m_InventoryPanels = []

var INVENTORY_SIZE = 6

function UpdateInventory()
{
	var queryUnit = $.GetContextPanel().heroIndex;
	if (Number.isInteger(queryUnit)) {
		for ( var i = 0; i < INVENTORY_SIZE; ++i )
		{
			var inventoryPanel = m_InventoryPanels[i]
			var item = Entities.GetItemInSlot( queryUnit, i );
			inventoryPanel.SetItem( queryUnit, item );
		}
	}
}

function CreateInventoryPanels()
{
	var firstRowPanel = $( "#inventory_row_1" );
	var secondRowPanel = $( "#inventory_row_2" );
	if ( !firstRowPanel || !secondRowPanel )
		return;

	firstRowPanel.RemoveAndDeleteChildren();
	secondRowPanel.RemoveAndDeleteChildren();
	m_InventoryPanels = []

	for ( var i = 0; i < INVENTORY_SIZE; ++i )
	{
		var parentPanel = firstRowPanel;
		if ( i > 2 )
		{
			parentPanel = secondRowPanel;
		}

		var inventoryPanel = $.CreatePanel( "Panel", parentPanel, "" );
		inventoryPanel.BLoadLayout( "file://{resources}/layout/custom_game/inventory_item.xml", false, false );
		inventoryPanel.SetItemSlot( i );

		m_InventoryPanels.push( inventoryPanel );
	}
}


(function()
{
	CreateInventoryPanels();
	UpdateInventory();

	GameEvents.Subscribe( "dota_inventory_changed", UpdateInventory );
	GameEvents.Subscribe( "dota_inventory_item_changed", UpdateInventory );
	GameEvents.Subscribe( "m_event_dota_inventory_changed_query_unit", UpdateInventory );
	GameEvents.Subscribe( "m_event_keybind_changed", UpdateInventory );
	GameEvents.Subscribe( "dota_player_update_selected_unit", UpdateInventory );
	GameEvents.Subscribe( "dota_player_update_query_unit", UpdateInventory );
})();

