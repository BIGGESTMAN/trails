"use strict";

var m_Item = -1;
var m_ItemSlot = -1;
var m_QueryUnit = -1;

function UpdateItem()
{
	var itemName = Abilities.GetAbilityName( m_Item );
	var hotkey = Abilities.GetKeybind( m_Item, m_QueryUnit );
	var isPassive = Abilities.IsPassive( m_Item );
	var chargeCount = 0;
	var hasCharges = false;
	var altChargeCount = 0;
	var hasAltCharges = false;
	var manaCost = Abilities.GetManaCost( m_Item );
	var unitMana = Entities.GetMana( m_QueryUnit );
	
	if ( Items.ShowSecondaryCharges( m_Item ) )
	{
		// Ward stacks display charges differently depending on their toggle state
		hasCharges = true;
		hasAltCharges = true;
		if ( Abilities.GetToggleState( m_Item ) )
		{
			chargeCount = Items.GetCurrentCharges( m_Item );
			altChargeCount = Items.GetSecondaryCharges( m_Item );
		}
		else
		{
			altChargeCount = Items.GetCurrentCharges( m_Item );
			chargeCount = Items.GetSecondaryCharges( m_Item );
		}
	}
	else if ( Items.ShouldDisplayCharges( m_Item ) )
	{
		hasCharges = true;
		chargeCount = Items.GetCurrentCharges( m_Item );
	}

	$.GetContextPanel().SetHasClass( "no_item", (m_Item == -1) );
	$.GetContextPanel().SetHasClass( "show_charges", hasCharges );
	$.GetContextPanel().SetHasClass( "show_alt_charges", hasAltCharges );
	$.GetContextPanel().SetHasClass( "is_passive", isPassive );
	$.GetContextPanel().SetHasClass( "insufficient_mana", ( manaCost > unitMana ) );
	
	$( "#HotkeyText" ).text = hotkey;
	$( "#ItemImage" ).itemname = itemName;
	$( "#ItemImage" ).contextEntityIndex = m_Item;
	$( "#ChargeCount" ).text = chargeCount;
	$( "#AltChargeCount" ).text = altChargeCount;
	$( "#ManaCost" ).text = manaCost;
	
	if ( m_Item == -1 || Abilities.IsCooldownReady( m_Item ) )
	{
		$.GetContextPanel().SetHasClass( "cooldown_ready", true );
		$.GetContextPanel().SetHasClass( "in_cooldown", false );
	}
	else
	{
		$.GetContextPanel().SetHasClass( "cooldown_ready", false );
		$.GetContextPanel().SetHasClass( "in_cooldown", true );
		var cooldownLength = Abilities.GetCooldownLength( m_Item );
		var cooldownRemaining = Abilities.GetCooldownTimeRemaining( m_Item );
		var cooldownPercent = Math.ceil( 100 * cooldownRemaining / cooldownLength );
		var cooldownText = Math.ceil(cooldownRemaining * 10) / 10;
		if (cooldownRemaining > 1) {
			cooldownText = Math.ceil(cooldownRemaining)
		}
		$( "#CooldownTimer" ).text = cooldownText;
		$("#CooldownOverlay").style.clip = "radial( 50% 50%, 0deg, " + (-1 * cooldownPercent * 360 / 100) + "deg )"
	}
	
	$.Schedule( 1/30, UpdateItem );
}

function ItemShowTooltip()
{
	if ( m_Item == -1 )
		return;

	// var tooltipPanel = $.CreatePanel("Panel", $.GetContextPanel(), "MasterQuartzTooltipPanel");
	// tooltipPanel.BLoadLayout("file://{resources}/layout/custom_game/master_quartz_tooltip.xml", false, false);
	// $.GetContextPanel().tooltipPanel = tooltipPanel
	// $.Msg(tooltipPanel, "\n", $.GetContextPanel().tooltipPanel)
	// tooltipPanel.style.position = $.GetContextPanel().style.position

	// var arg_string = "abilities="
	// var abilities = []
	// for (var i=0; i < 5; i++) {
	// 	abilities.push(m_Item)
	// 	// arg_string = arg_string + "abil" + i + "=" + abilities[i] + ";"
	// 	arg_string = arg_string + abilities[i] + ";"
	// }
	var itemName = Abilities.GetAbilityName( m_Item );
	if (itemName.substr(0, ("item_master_").length) != "item_master_") {
		$.DispatchEvent( "DOTAShowAbilityTooltipForEntityIndex", $.GetContextPanel(), itemName, m_QueryUnit );
	} else {
		var arg_string = "masterquartz=" + m_Item
		$.DispatchEvent("UIShowCustomLayoutParametersTooltip", $.GetContextPanel(), "file://{resources}/layout/custom_game/master_quartz_tooltip.xml", arg_string);
	}
	// $.DispatchEvent("UIShowCustomLayoutParametersTooltip", $.GetContextPanel(), "file://{resources}/layout/tooltips/tooltip_custom_test.xml", {itemID : m_Item});
	// UIShowCustomLayoutParametersTooltip("MasterQuartzTooltip", "file://{resources}/layout/tooltips/tooltip_custom_test.xml", itemID=m_Item)
}

function ItemHideTooltip()
{
	// if ( m_Item == -1 )
		// return;
	// $.GetContextPanel().tooltipPanel.DeleteAsync( 0 );

	$.DispatchEvent( "DOTAHideAbilityTooltip", $.GetContextPanel() );

	$.DispatchEvent("UIHideCustomLayoutTooltip", $.GetContextPanel())

	// $.DispatchEvent( "DOTAHideTextTooltip", $.GetContextPanel() );
}

function ActivateItem()
{
	if ( m_Item == -1 )
		return;

	// Items are abilities - just execute the ability
	Abilities.ExecuteAbility( m_Item, m_QueryUnit, false );
}

function DoubleClickItem()
{
	ActivateItem();
}

var DOTA_ITEM_STASH_MIN = 6;

function IsInStash()
{
	return ( m_ItemSlot >= DOTA_ITEM_STASH_MIN );
}

function RightClickItem()
{
	// ItemHideTooltip();

	// var bSlotInStash = IsInStash();
	// var bControllable = Entities.IsControllableByPlayer( m_QueryUnit, Game.GetLocalPlayerID() );
	// var bSellable = Items.IsSellable( m_Item ) && Items.CanBeSoldByLocalPlayer( m_Item );
	// var bDisassemble = Items.IsDisassemblable( m_Item ) && bControllable && !bSlotInStash;
	// var bAlertable = Items.IsAlertableItem( m_Item );
	// var bShowInShop = Items.IsPurchasable( m_Item );
	// var bDropFromStash = bSlotInStash && bControllable;

	// if ( !bSellable && !bDisassemble && !bShowInShop && !bDropFromStash && !bAlertable && !bMoveToStash )
	// {
	// 	// don't show a menu if there's nothing to do
	// 	return;
	// }

	// var contextMenu = $.CreatePanel( "Panel", $.GetContextPanel(), "" );
	// // contextMenu.BLoadLayout("DOTAContextMenuScript", false, false)
	// contextMenu.AddClass( "ContextMenu_NoArrow" );
	// contextMenu.AddClass( "ContextMenu_NoBorder" );
	// contextMenu.Item = m_Item;
	// contextMenu.SetHasClass( "bSellable", bSellable );
	// contextMenu.SetHasClass( "bDisassemble", bDisassemble );
	// contextMenu.SetHasClass( "bShowInShop", bShowInShop );
	// contextMenu.SetHasClass( "bDropFromStash", bDropFromStash );
	// contextMenu.SetHasClass( "bAlertable", bAlertable );
	// contextMenu.SetHasClass( "bMoveToStash", false ); // TODO
	// contextMenu.BLoadLayout( "file://{resources}/layout/custom_game/inventory_context_menu.xml", false, false );
}

function OnDragEnter( a, draggedPanel )
{
	var draggedItem = draggedPanel.m_DragItem;

	// only care about dragged items other than us
	if ( draggedItem === null || draggedItem == m_Item )
		return true;

	// highlight this panel as a drop target
	$.GetContextPanel().AddClass( "potential_drop_target" );
	return true;
}

function OnDragDrop( panelId, draggedPanel )
{
	var draggedItem = draggedPanel.m_DragItem;
	
	// only care about dragged items other than us
	if ( draggedItem === null )
		return true;

	// executing a slot swap - don't drop on the world
	draggedPanel.m_DragCompleted = true;
	
	// item dropped on itself? don't acutally do the swap (but consider the drag completed)
	if ( draggedItem == m_Item )
		return true;

	// create the order
	var moveItemOrder =
	{
		OrderType: dotaunitorder_t.DOTA_UNIT_ORDER_MOVE_ITEM,
		TargetIndex: m_ItemSlot,
		AbilityIndex: draggedItem
	};
	Game.PrepareUnitOrders( moveItemOrder );
	return true;
}

function OnDragLeave( panelId, draggedPanel )
{
	var draggedItem = draggedPanel.m_DragItem;
	if ( draggedItem === null || draggedItem == m_Item )
		return false;

	// un-highlight this panel
	$.GetContextPanel().RemoveClass( "potential_drop_target" );
	return true;
}

function OnDragStart( panelId, dragCallbacks )
{
	if ( m_Item == -1 )
	{
		return true;
	}

	var itemName = Abilities.GetAbilityName( m_Item );

	ItemHideTooltip(); // tooltip gets in the way

	// create a temp panel that will be dragged around
	var displayPanel = $.CreatePanel( "DOTAItemImage", $.GetContextPanel(), "dragImage" );
	displayPanel.itemname = itemName;
	displayPanel.contextEntityIndex = m_Item;
	displayPanel.m_DragItem = m_Item;
	displayPanel.m_DragCompleted = false; // whether the drag was successful

	// hook up the display panel, and specify the panel offset from the cursor
	dragCallbacks.displayPanel = displayPanel;
	dragCallbacks.offsetX = 0;
	dragCallbacks.offsetY = 0;
	
	// grey out the source panel while dragging
	$.GetContextPanel().AddClass( "dragging_from" );
	return true;
}

function OnDragEnd( panelId, draggedPanel )
{
	// if the drag didn't already complete, then try dropping in the world
	if ( !draggedPanel.m_DragCompleted )
	{
		Game.DropItemAtCursor( m_QueryUnit, m_Item );
	}

	// kill the display panel
	draggedPanel.DeleteAsync( 0 );

	// restore our look
	$.GetContextPanel().RemoveClass( "dragging_from" );
	return true;
}

function SetItemSlot( itemSlot )
{
	m_ItemSlot = itemSlot;
}

function SetItem( queryUnit, iItem )
{
	m_Item = iItem;
	m_QueryUnit = queryUnit;
}

(function()
{
	$.GetContextPanel().SetItem = SetItem;
	$.GetContextPanel().SetItemSlot = SetItemSlot;

	// Drag and drop handlers ( also requires 'draggable="true"' in your XML, or calling panel.SetDraggable(true) )
	$.RegisterEventHandler( 'DragEnter', $.GetContextPanel(), OnDragEnter );
	$.RegisterEventHandler( 'DragDrop', $.GetContextPanel(), OnDragDrop );
	$.RegisterEventHandler( 'DragLeave', $.GetContextPanel(), OnDragLeave );
	$.RegisterEventHandler( 'DragStart', $.GetContextPanel(), OnDragStart );
	$.RegisterEventHandler( 'DragEnd', $.GetContextPanel(), OnDragEnd );

	UpdateItem(); // initial update of dynamic state
})();
