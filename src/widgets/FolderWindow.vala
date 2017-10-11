/*
* Copyright (c) 2017 José Amuedo (https://github.com/spheras)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*/

/**
* @class
* Folder Window that is shown above the desktop to manage files and folders
*/
public class DesktopFolder.FolderWindow : Gtk.ApplicationWindow{
    /** parent manager of this window */
    private FolderManager manager=null;
    /** container of widgets */
    private Gtk.Fixed container=null;
    /** Context menu of the Folder Window */
    private Gtk.Menu menu=null;

    /** head tags colors */
    private const string HEAD_TAGS_COLORS[3] = { null, "#ffffff", "#000000"};
    private const string HEAD_TAGS_COLORS_CLASS[3] = { "headless", "light", "dark"};
    /** body tags colors */
    private const string BODY_TAGS_COLORS[10] = { null, "#fce94f", "#fcaf3e", "#997666", "#8ae234", "#729fcf", "#ad7fa8", "#ef2929", "#d3d7cf", "#000000" };
    private const string BODY_TAGS_COLORS_CLASS[10] = { "transparent", "yellow", "orange", "brown", "green", "blue", "purple", "red", "gray", "black" };

    construct {
        set_keep_below (true);
        stick ();
        this.hide_titlebar_when_maximized = false;
        set_type_hint(Gdk.WindowTypeHint.MENU);
        set_skip_taskbar_hint(true);
        this.set_property("skip-taskbar-hint", true);
    }

    /**
    * @constructor
    * @param FolderManager manager the manager of this window
    */
    public FolderWindow (FolderManager manager){
        Object (application: manager.get_application(),
                icon_name: "com.github.spheras.desktopfolder",
                resizable: true,
                skip_taskbar_hint : true,
                decorated:true,
                title: (manager.get_folder_name()),
                deletable:false,
                default_width:300,
                default_height:300,
                height_request: 50,
                width_request: 50);


        var headerbar = new Gtk.HeaderBar();
        headerbar.set_title(manager.get_folder_name());
        //headerbar.set_subtitle("HeaderBar Subtitle");
        //headerbar.set_show_close_button(true);
        this.set_titlebar(headerbar);

        this.set_skip_taskbar_hint(true);
        this.set_property("skip-taskbar-hint", true);
        //setting the folder name
        this.manager=manager;

        //we set a class to this window to manage the css
        this.get_style_context ().add_class ("df_folder");

        //creating the container widget
        this.container=new Gtk.Fixed();
        add(this.container);

        //let's load the settings of the folder (if exist or a new one)
        FolderSettings settings=this.manager.get_settings();
        if(settings.w>0){
            //applying existing position and size configuration
            this.resize(settings.w,settings.h);
            this.move(settings.x,settings.y);
        }
        //applying existing colors configuration
        this.get_style_context ().add_class (settings.bgcolor);
        this.get_style_context ().add_class (settings.fgcolor);

        //connecting to events
        this.configure_event.connect (this.on_configure);
        this.button_press_event.connect(this.on_press);
        this.key_release_event.connect(this.on_key);
        this.key_press_event.connect(this.on_key);

        //TODO this.dnd_behaviour=new DragnDrop.DndBehaviour(this,false, true);
    }

    /**
    * @name refresh
    * @description refresh the window
    */
    public void refresh(){
        this.show_all();
    }

    /**
    * @name on_configure
    * @description the configure event is produced when the window change its dimensions or location settings
    */
    private bool on_configure(Gdk.EventConfigure event){
        if(event.type==Gdk.EventType.CONFIGURE){
            //debug("configure event:%i,%i,%i,%i",event.x,event.y,event.width,event.height);
            this.manager.set_new_shape(event.x, event.y, event.width, event.height);
        }
        return false;
    }

    /**
    * @name on_press
    * @description press event captured. The Window should show the popup on right button
    * @return bool @see widget on_press signal
    */
    private bool on_press(Gdk.EventButton event){
        //debug("press:%i,%i",(int)event.button,(int)event.y);
        if (event.type == Gdk.EventType.BUTTON_PRESS &&
            (event.button==Gdk.BUTTON_SECONDARY)) {
            this.show_popup(event);
            return true;
        }
        return false;
    }

    /**
    * @name show_popup
    * @description build and show the popup menu
    * @param event EventButton the origin event, needed to position the menu
    */
    private void show_popup(Gdk.EventButton event){
        //debug("evento:%f,%f",event.x,event.y);
        //if(this.menu==null) { //we need the event coordinates for the menu, we need to recreate?!
            this.menu = new Gtk.Menu ();

            //section to change the window head and body colors
            Gtk.MenuItem item = new MenuItemColor(HEAD_TAGS_COLORS);;
            ((MenuItemColor)item).color_changed.connect(change_head_color);
            item.show();
            menu.append (item);
            item = new MenuItemColor(BODY_TAGS_COLORS);;
            ((MenuItemColor)item).color_changed.connect(change_body_color);
            item.show();
            menu.append (item);

            item = new MenuItemSeparator();
            item.show();
            menu.append (item);

            //menu to create a new folder
            item = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_NEW_DESKTOP_FOLDER);
            item.activate.connect ((item)=>{
                    this.new_desktop_folder();
            });
            item.show();
            menu.append (item);

            //menu to create a new note
            item = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_NEW_NOTE);
            item.activate.connect ((item)=>{
                    this.new_note();
            });
            item.show();
            menu.append (item);

            //menu to create a new photo
            item = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_NEW_PHOTO);
            item.activate.connect ((item)=>{
                    this.new_photo();
            });
            item.show();
            menu.append (item);


            item = new MenuItemSeparator();
            item.show();
            menu.append (item);

            //menu to create a new folder
            item = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_NEW_FOLDER);
            item.activate.connect ((item)=>{
                    this.new_folder((int)event.x, (int)event.y);
            });
            item.show();
            menu.append (item);

            //menu to create a new text file
            item = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_NEW_TEXT_FILE);
            item.activate.connect ((item)=>{
                    this.new_text_file((int)event.x, (int)event.y);
            });
            item.show();
            menu.append (item);

            //menu to create a new link file
            item = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_NEW_FILE_LINK);
            item.activate.connect ((item)=>{
                    this.new_link((int)event.x, (int)event.y,false);
            });
            item.show();
            menu.append (item);

            //menu to create a new link folder
            item = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_NEW_FOLDER_LINK);
            item.activate.connect ((item)=>{
                    this.new_link((int)event.x, (int)event.y,true);
            });
            item.show();
            menu.append (item);

            //Option to rename the current folder
            item = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_RENAME_DESKTOP_FOLDER);
            item.activate.connect ((item)=>{this.rename_folder();});
            item.show();
            menu.append (item);

            //option to delete the current folder
            item = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_REMOVE_DESKTOP_FOLDER);
            item.activate.connect ((item)=>{this.delete_folder();});
            item.show();
            menu.append (item);

            item = new MenuItemSeparator();
            item.show();
            menu.append (item);

            //If the paste is available, a paste option
            Clipboard.ClipboardManager cm=Clipboard.ClipboardManager.get_for_display ();
            if(cm.can_paste){

                item = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_PASTE);
                item.activate.connect ((item)=>{this.manager.paste();});
                item.show();
                menu.append (item);

                item = new MenuItemSeparator();
                item.show();
                menu.append (item);
            }

            //the about option to show a message dialog
            item = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_ABOUT);
            item.activate.connect ((item)=>{
                DesktopFolder.Util.show_about(this);
            });
            item.show();
            menu.append (item);
            menu.show_all();

            item = new Gtk.MenuItem.with_label (DesktopFolder.Lang.HINT_SHOW_DESKTOP);
            item.show();
            menu.append (item);
            menu.show_all();

        //}

        //finally we show the popup
        menu.popup(
             null //parent menu shell
            ,null //parent menu item
            ,null //func
            ,event.button // button
            ,event.get_time() //Gtk.get_current_event_time() //time
            );
    }

    /**
    * @name change_head_color
    * @description change event captured from the popup for a new color to the head window
    * @param ncolor int the new color for the head window
    */
    private void change_head_color(int ncolor){
        string color=HEAD_TAGS_COLORS_CLASS[ncolor];
        for(int i=0;i<HEAD_TAGS_COLORS_CLASS.length;i++){
            string scolor=HEAD_TAGS_COLORS_CLASS[i];
            this.get_style_context().remove_class (scolor);
        }
        this.get_style_context ().add_class (color);
        this.manager.save_head_color(color);
        //debug("color:%d,%s",ncolor,color);
    }

    /**
    * @name move_item
    * @description move an item inside this window to a certain position
    * @param int x the x position
    * @param int y the y position
    */
    public void move_item(ItemView item, int x, int y){
        this.container.move(item,x,y);
    }

    /**
    * @name change_body_color
    * @description change event captured from the popup for a new color to the body window
    * @param ncolor int the new color for the body window
    */
    private void change_body_color(int ncolor){
        string color=BODY_TAGS_COLORS_CLASS[ncolor];
        for(int i=0;i<BODY_TAGS_COLORS_CLASS.length;i++){
            string scolor=BODY_TAGS_COLORS_CLASS[i];
            this.get_style_context().remove_class (scolor);
        }

        this.get_style_context().add_class (color);
        this.manager.save_body_color(color);
        //debug("color:%d,%s",ncolor,color);
    }

    /**
    * @name clear_all
    * @description clear all the items inside this folder window
    */
    public void clear_all(){
        //debug("clearing all items");
        var children = this.container.get_children ();
        foreach (Gtk.Widget element in children)
            this.container.remove (element);
    }

    /**
    * @name add_item
    * @description add an item icon to the container
    * @param ItemView item the item to be added
    * @param int x the x position where it should be placed
    * @param int y the y position where it should be placed
    */
    public void add_item(ItemView item, int x, int y){
        //debug("position:%d,%d",is.x,is.y);
        this.container.put(item,x,y);
    }

    public void raise(ItemView item,int x,int y){
        this.container.remove(item);
        add_item(item,x,y);
    }

    /**
    * @name on_key
    * @description the key event captured for the window
    * @param EventKey event the event produced
    * @return bool @see the on_key signal
    */
    private bool on_key(Gdk.EventKey event){
        int key=(int)event.keyval;
        //debug("event key %d",key);
        //this is the delete key code
        const int DELETE_KEY=65535;
        const int F2_KEY=65471;
        const int INTRO_KEY=65293;
        const int ARROW_LEFT_KEY=65361;
        const int ARROW_UP_KEY=65362;
        const int ARROW_RIGHT_KEY=65363;
        const int ARROW_DOWN_KEY=65364;

        //check if the control key is pressed
        var mods = event.state & Gtk.accelerator_get_default_mod_mask ();
        bool control_pressed = ((mods & Gdk.ModifierType.CONTROL_MASK) != 0);

        if(event.type==Gdk.EventType.KEY_RELEASE && key==DELETE_KEY){
            //delete key pressed!
            ItemView selected=this.get_selected_item();
            if(selected!=null){
                selected.delete_dialog();
                return true;
            }
            return false;
        }else if(event.type==Gdk.EventType.KEY_RELEASE && key==F2_KEY){
            //ctrl+c key pressed
            ItemView selected=this.get_selected_item();
            if(selected!=null){
                selected.rename_dialog();
                return true;
            }
            return false;
        }else if(control_pressed && event.type==Gdk.EventType.KEY_RELEASE && (key=='c' || key=='C')){
            //ctrl+c key pressed
            ItemView selected=this.get_selected_item();
            if(selected!=null) {
                selected.copy();
                return true;
            }
            return false;
        }else if(control_pressed && event.type==Gdk.EventType.KEY_RELEASE && (key=='x' || key=='X')){
            //ctrl+x key pressed
            ItemView selected=this.get_selected_item();
            if(selected!=null) {
                selected.cut();
                return true;
            }
            return false;
        }else if(control_pressed && event.type==Gdk.EventType.KEY_RELEASE && (key=='v' || key=='V')){
            //ctrl+v key pressed
            this.manager.paste();
        }else if(event.type==Gdk.EventType.KEY_RELEASE && key==INTRO_KEY){
            //INTRO key pressed
            ItemView selected=this.get_selected_item();
            if(selected!=null) {
                selected.execute();
                return true;
            }
        }else if(event.type==Gdk.EventType.KEY_PRESS && key==ARROW_LEFT_KEY){
            //left arrow pressed
            move_selected_to((a,b)=>{
                return (b.y>=a.y && b.y<=(a.y+a.height)) || (a.y>=b.y && a.y<=(b.y+b.height));
            },(a,b)=>{
                return a.x < b.x;
            });
        }else if(event.type==Gdk.EventType.KEY_PRESS && key==ARROW_UP_KEY){
            //up arrow pressed
            move_selected_to((a,b)=>{
                return (b.x>=a.x && b.x<=(a.x+a.width)) || (a.x>=b.x && a.x<=(b.x+b.width));
            },(a,b)=>{
                return a.y < b.y;
            });
        }else if(event.type==Gdk.EventType.KEY_PRESS && key==ARROW_RIGHT_KEY){
            //right arrow pressed
            move_selected_to((a,b)=>{
                return (b.y>=a.y && b.y<=(a.y+a.height)) || (a.y>=b.y && a.y<=(b.y+b.height));
            },(a,b)=>{
                return a.x > b.x;
            });
        }else if(event.type==Gdk.EventType.KEY_PRESS && key==ARROW_DOWN_KEY){
            //down arrow pressed
            move_selected_to((a,b)=>{
                return (b.x>=a.x && b.x<=(a.x+a.width)) || (a.x>=b.x && a.x<=(b.x+b.width));
            },(a,b)=>{
                return a.y > b.y;
            });
        }
        return false;
    }

    /**
    * @name CompareAllocations
    * @description Comparator of GtkAllocation objects to order the selection with the keyboard
    * @return {bool} if the a element is greater than the b element
    */
    private delegate bool CompareAllocations(Gtk.Allocation a, Gtk.Allocation b);

    /**
    * @name move_selected_to
    * @description select the next item following a direction
    * @param {CompareAllocations} same_axis;
    * @param {CompareAllocations} is_selectable
    */
    private void move_selected_to(CompareAllocations same_axis, CompareAllocations is_selectable){
        List<weak Gtk.Widget> children = this.container.get_children();
        ItemView actual_item = this.get_selected_item();
        Gtk.Allocation actual_allocation;
        actual_item.get_allocation(out actual_allocation);
        ItemView next_item = null;
        Gtk.Allocation next_allocation=actual_allocation;
        foreach (Gtk.Widget elem in children ) {
            Gtk.Allocation elem_allocation;
            elem.get_allocation(out elem_allocation);
            if(same_axis(elem_allocation,actual_allocation) && is_selectable(elem_allocation,actual_allocation)){
                if(next_item==null){
                    //If this is the first element is selectable found
                    next_allocation=elem_allocation;
                    next_item=(ItemView)elem;
                }else if (!is_selectable(elem_allocation,next_allocation)) {
                    //If it is nearer from the last found
                    next_allocation=elem_allocation;
                    next_item=(ItemView)elem;
                }
            }
        }
        if(next_item!=null){
            next_item.select();
        }else {
            debug("There are no elements on this direction");
        }
    }

    /**
    * @name get_selected_item
    * @description return the selected item
    * @return ItemView return the selected item at the desktop folder, or null if none selected
    */
    private ItemView get_selected_item(){
        var children = this.container.get_children ();
        for(int i=0;i<children.length();i++){
            ItemView element=(ItemView) children.nth_data(i);
            if(element.is_selected()){
                return element;
            }
        }
        return null as ItemView;
    }

    /**
    * @name new_desktop_folder
    * @description show a dialog to create a new desktop folder
    */
    private void new_desktop_folder(){
        DesktopFolder.Util.create_new_desktop_folder(this);
    }

    /**
    * @name new_note
    * @description show a dialog to create a new note
    */
    private void new_note(){
        DesktopFolder.Util.create_new_note(this);
    }

    /**
    * @name new_photo
    * @description show a dialog to create a new photo
    */
    private void new_photo(){
        DesktopFolder.Util.create_new_photo(this);
    }

    /**
    * @name new_folder
    * @description show a dialog to create a new folder
    * @param int x the x position where the new folder icon should be generated
    * @param int y the y position where the new folder icon should be generated
    */
    private void new_folder(int x, int y){
        RenameDialog dialog = new RenameDialog (this,
                                                DesktopFolder.Lang.DESKTOPFOLDER_NEW_FOLDER_TITLE,
                                                DesktopFolder.Lang.DESKTOPFOLDER_NEW_FOLDER_MESSAGE,
                                                DesktopFolder.Lang.DESKTOPFOLDER_NEW_FOLDER_NAME);
        dialog.on_rename.connect((new_name)=>{
            //creating the folder
            if(new_name!=""){
                this.manager.create_new_folder(new_name,x, y);
            }
        });
        dialog.show_all ();
    }

    /**
    * @name new_text_file
    * @description create a new text file item inside this folder
    * @param int x the x position where the new item should be placed
    * @param int y the y position where the new item should be placed
    */
    private void new_text_file(int x, int y){
        RenameDialog dialog = new RenameDialog (this,
                                                DesktopFolder.Lang.DESKTOPFOLDER_NEW_TEXT_FILE_TITLE,
                                                DesktopFolder.Lang.DESKTOPFOLDER_NEW_TEXT_FILE_MESSAGE,
                                                DesktopFolder.Lang.DESKTOPFOLDER_NEW_TEXT_FILE_NAME);
        dialog.on_rename.connect((new_name)=>{
            if(new_name!=""){
                this.manager.create_new_text_file(new_name, x, y);
            }
        });
        dialog.show_all ();
    }

    /**
    * @name new_link
    * @description create a new linnk item inside this folder
    * @param int x the x position where the new item should be placed
    * @param int y the y position where the new item should be placed
    * @param bool folder to indicate if we want to select a folder or a file
    */
    private void new_link(int x, int y, bool folder){
        Gtk.FileChooserDialog chooser = new Gtk.FileChooserDialog (
				DesktopFolder.Lang.DESKTOPFOLDER_LINK_MESSAGE, this, Gtk.FileChooserAction.OPEN,
				DesktopFolder.Lang.DIALOG_CANCEL,
				Gtk.ResponseType.CANCEL,
				DesktopFolder.Lang.DIALOG_SELECT,
				Gtk.ResponseType.ACCEPT);

        if(folder){
            chooser.set_action(Gtk.FileChooserAction.SELECT_FOLDER);
        }
        // Process response:
		if (chooser.run () == Gtk.ResponseType.ACCEPT) {
            var filename=chooser.get_filename();
            debug("file:%s",filename);
            this.manager.create_new_link(filename, x, y);
		}
        chooser.close();
    }

    /**
    * @name delete_folder
    * @description try to delete the current desktop folder
    */
    private void delete_folder(){
        //we need to ask and be sure
        string message=DesktopFolder.Lang.DESKTOPFOLDER_DELETE_MESSAGE;
        Gtk.MessageDialog msg = new Gtk.MessageDialog (this, Gtk.DialogFlags.MODAL, Gtk.MessageType.WARNING,
                                                       Gtk.ButtonsType.OK_CANCEL, message);
       msg.use_markup=true;
        msg.response.connect ((response_id) => {
            switch (response_id) {
				case Gtk.ResponseType.OK:
                    msg.destroy();
                    this.manager.delete();
					break;
                default:
                    msg.destroy();
                    break;
                    //uff
            }
        });
        msg.show ();
    }

    /**
    * @name rename_folder
    * @description try to rename the current desktop folder
    */
    private void rename_folder(){
        RenameDialog dialog = new RenameDialog (this,
                                                DesktopFolder.Lang.DESKTOPFOLDER_RENAME_TITLE,
                                                DesktopFolder.Lang.DESKTOPFOLDER_RENAME_MESSAGE,
                                                this.manager.get_folder_name());
        dialog.on_rename.connect((new_name)=>{
            if(this.manager.rename(new_name)){
                this.set_title(new_name);
            }
        });
        dialog.show_all ();
    }

    /**
    * @name unselect_all
    * @description unselect all the items inside this folder
    */
    public void unselect_all(){
        var children = this.container.get_children ();
        foreach (Gtk.Widget element in children){
            ((ItemView)element).unselect();
        }
    }

}
