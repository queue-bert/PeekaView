//
//  GStreamerBackend.c
//  GStreamerSwiftUIDemo
//
//  Created by Raktim Bora on 19.06.23.
//

#include<unistd.h>
#include "GStreamerBackend.h"
# include "gst_ios_init.h"
#include <UIKit/UIKit.h>

#include <GStreamer/gst/gst.h>
#include <GStreamer/gst/video/video.h>
#import "PeekaView-Swift.h"

GST_DEBUG_CATEGORY_STATIC (debug_category);
#define GST_CAT_DEFAULT debug_category

@interface GStreamerBackend()
-(void)setUIMessage:(gchar*) message;
//-(void)initializeColorChannels;
-(void)run_app_pipeline;
-(void)check_initialization_complete;
@end

@implementation GStreamerBackend {
    id ui_delegate;        /* Class that we use to interact with the user interface */
    GstElement *pipeline;  /* The running pipeline */
    GstElement *video_sink;/* The video sink element which receives XOverlay commands */
    GMainContext *context; /* GLib context used to run the main loop */
    GMainLoop *main_loop;  /* GLib main loop */
    gboolean initialized;  /* To avoid informing the UI multiple times about the initialization */
    GstBus *bus;
    UIView *ui_video_view; /* UIView that holds the video */
    GstMessage* eos_msg;
}

/*
 * Interface methods
 */

-(id) init:(id) uiDelegate videoView:(UIView *)video_view
{
    if (self = [super init])
    {
        self->ui_delegate = uiDelegate;
        self->ui_video_view = video_view;
        
        GST_DEBUG_CATEGORY_INIT (debug_category, "GStreamerSwiftUIDemo", 0, "GStreamerSwiftUIDemo-Backend");
        gst_debug_set_threshold_for_name("GStreamerSwiftUIDemo", GST_LEVEL_INFO);
    }
    
    return self;
}

-(void) run_app_pipeline_threaded
{
    [self run_app_pipeline];
    return;
}



-(void) play
{
    if(gst_element_set_state(pipeline, GST_STATE_PLAYING) == GST_STATE_CHANGE_FAILURE) {
        [self setUIMessage:"Failed to set pipeline to playing"];
    }
}


-(void) pause
{
    if(gst_element_set_state(pipeline, GST_STATE_PAUSED) == GST_STATE_CHANGE_FAILURE) {
        [self setUIMessage:"Failed to set pipeline to paused"];
    }
}

-(void) destroy
{
    if(gst_element_set_state(pipeline, GST_STATE_PAUSED) == GST_STATE_CHANGE_FAILURE) {
        [self setUIMessage:"Failed to set pipeline to READY"];
    }
    eos_msg = gst_message_new_eos(GST_OBJECT(pipeline));
    gst_element_post_message (pipeline, eos_msg);
}


/* Change the message on the UI through the UI delegate */
-(void)setUIMessage:(gchar*) message
{
    NSString *messagString = [NSString stringWithUTF8String:message];
    if(ui_delegate && [ui_delegate respondsToSelector:@selector(gstreamerSetUIMessageWithMessageWithMessage:)])
    {
        [ui_delegate gstreamerSetUIMessageWithMessageWithMessage:messagString];
    }
}

static void eos_cb(GstBus *bus, GstMessage *msg, GStreamerBackend *self){
    printf("\neos called\n");
    gst_element_set_state (self->pipeline, GST_STATE_NULL);
    g_main_loop_quit(self->main_loop);
}

/* Retrieve errors from the bus and show them on the UI */
static void error_cb (GstBus *bus, GstMessage *msg, GStreamerBackend *self)
{
    GError *err;
    gchar *debug_info;
    gchar *message_string;
    
    gst_message_parse_error (msg, &err, &debug_info);
    message_string = g_strdup_printf ("Error received from element %s: %s", GST_OBJECT_NAME (msg->src), err->message);
    printf("Some error occured in from element %s: %s", GST_OBJECT_NAME (msg->src), err->message);
    g_clear_error (&err);
    g_free (debug_info);
    [self setUIMessage:message_string];
    g_free (message_string);
    gst_element_set_state (self->pipeline, GST_STATE_NULL);
}

/* Notify UI about pipeline state changes */
static void state_changed_cb (GstBus *bus, GstMessage *msg, GStreamerBackend *self)
{
    GstState old_state, new_state, pending_state;
    gst_message_parse_state_changed (msg, &old_state, &new_state, &pending_state);
    /* Only pay attention to messages coming from the pipeline, not its children */
    if (GST_MESSAGE_SRC (msg) == GST_OBJECT (self->pipeline)) {
        gchar *message = g_strdup_printf("State changed from %s to %s", gst_element_state_get_name(old_state), gst_element_state_get_name(new_state));
        [self setUIMessage:message];
        g_free (message);
    }
}

/* Check if all conditions are met to report GStreamer as initialized.
 * These conditions will change depending on the application */
-(void) check_initialization_complete
{
    if (!initialized && main_loop) {
        GST_DEBUG ("Initialization complete, notifying application.");
        if (ui_delegate && [ui_delegate respondsToSelector:@selector(gStreamerInitialized)])
        {
            [ui_delegate gStreamerInitialized];
        }
        initialized = TRUE;
    }
}

/* Main method */
-(void) run_app_pipeline
{
    GSource *bus_source;
    GError *error = NULL;
    
    GST_DEBUG ("Creating pipeline");
    
    /* Create our own GLib Main Context and make it the default one */
    context = g_main_context_new ();
    g_main_context_push_thread_default(context);
    
    /* Build pipeline */
    /* Change the RTSP URL to your desired URL below */
//    pipeline = gst_parse_launch("playbin uri=rtsp://username:password@ip_address/additional_stream_url", &error);
//    169.254.41.12
    pipeline = gst_parse_launch("playbin uri=rtsp://169.254.15.188:8554/stream", &error);
//    pipeline = gst_parse_launch("playbin uri=rtsp://169.254.41.12:8554/test", &error);
    
    
    if (error && !GST_IS_ELEMENT(pipeline)) {
        gchar *message = g_strdup_printf("Unable to build pipeline: %s", error->message);
        g_clear_error (&error);
        [self setUIMessage:message];
        g_free (message);
        return;
    }
    
    /* Set the pipeline to READY, so it can already accept a window handle */
    gst_element_set_state(pipeline, GST_STATE_READY);
    
    video_sink = gst_bin_get_by_interface(GST_BIN(pipeline), GST_TYPE_VIDEO_OVERLAY);
    if (!video_sink) {
        GST_ERROR ("Could not retrieve video sink");
        return;
    }
    gst_video_overlay_set_window_handle(GST_VIDEO_OVERLAY(video_sink), (guintptr) (id) ui_video_view);
    
    /* Signals to watch */
    bus = gst_element_get_bus (pipeline);
    bus_source = gst_bus_create_watch (bus);
    g_source_set_callback (bus_source, (GSourceFunc) gst_bus_async_signal_func, NULL, NULL);
    g_source_attach (bus_source, context);
    g_source_unref (bus_source);
    g_signal_connect (G_OBJECT (bus), "message::error", (GCallback)error_cb, (__bridge void *)self);
    g_signal_connect (G_OBJECT (bus), "message::eos", (GCallback)eos_cb, (__bridge void *)self);
    g_signal_connect (G_OBJECT (bus), "message::state-changed", (GCallback)state_changed_cb, (__bridge void *)self);
    gst_object_unref (bus);
    
    /* Create a GLib Main Loop and set it to run */
    GST_DEBUG ("Entering main loop...");
    printf("\nEntering main loop..\n");
    main_loop = g_main_loop_new (context, FALSE);
    //sleep(5);
    [self check_initialization_complete];
    g_main_loop_run (main_loop);
    GST_DEBUG ("Exited main loop");
    g_main_loop_unref (main_loop);
    main_loop = NULL;
    
    /* Free resources */
    g_main_context_pop_thread_default(context);
    g_main_context_unref (context);
    gst_element_set_state (pipeline, GST_STATE_NULL);
    gst_object_unref (pipeline);
    return;
}

//-(void)initializeColorChannels {
//    GstColorBalance *cb = GST_COLOR_BALANCE(pipeline);
//    const GList *channels, *l;
//
//    // Retrieve the list of channels from the color balance interface
//    channels = gst_color_balance_list_channels(cb);
//
//    for (l = channels; l != NULL; l = l->next) {
//        GstColorBalanceChannel *channel = (GstColorBalanceChannel *)l->data;
//        gint value = gst_color_balance_get_value(cb, channel);
//
//        NSString *channelName = [NSString stringWithUTF8String:channel->label];
//        gint appValue = (gint)(((value - channel->min_value) * 100) / (channel->max_value - channel->min_value));
//
//        if (ui_delegate && [ui_delegate respondsToSelector:@selector(updateColorChannelValueWithChannel:value:)]) {
//            [ui_delegate updateColorChannelValueWithChannel:channelName value:appValue];
//        }
//    }
//}


- (void)updateColorChannelWithName:(NSString *)channelName adjustmentMultiplier:(NSInteger)multiplier {
    const gchar *channel_name = [channelName UTF8String];
    update_color_channel(channel_name, multiplier, self);
}

static void update_color_channel(const gchar *channel_name, gint adjustment_multiplier, GStreamerBackend *self) {
    gdouble step;
    gint value, adjustment;
//    gint adjustment;
    GstColorBalance *cb = GST_COLOR_BALANCE(self->pipeline);
    GstColorBalanceChannel *channel = NULL;
    const GList *channels, *l;

    /* Retrieve the list of channels and locate the requested one */
    channels = gst_color_balance_list_channels(cb);
    for (l = channels; l != NULL; l = l->next) {
      GstColorBalanceChannel *tmp = (GstColorBalanceChannel *)l->data;

      if (g_strrstr(tmp->label, channel_name)) {
        channel = tmp;
        break;
      }
    }
    if (!channel)
      return;

    /* Calculate the step as 0.01 times the range, scaled by the adjustment_multiplier */
    step = 0.01 * (channel->max_value - channel->min_value) * (adjustment_multiplier-50);
    g_print("Calculated step: %f for adjustment_multiplier: %d\n", step, adjustment_multiplier);
//    step = 0.01 * (channel->max_value - channel->min_value);
    value = gst_color_balance_get_value(cb, channel);
//    adjustment = (gint)(adjustment_multiplier * step);
    adjustment = (gint)(value + step);
    g_print("Adjusting channel '%s' from %d to %d (min: %d, max: %d)\n",
            channel->label, value, adjustment, channel->min_value, channel->max_value);

    /* Bounds checking */
    if (adjustment > channel->max_value) {
        adjustment = channel->max_value;
    } else if (adjustment < channel->min_value) {
        adjustment = channel->min_value;
    }

    gst_color_balance_set_value(cb, channel, adjustment);
}

@end


