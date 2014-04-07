/*
    Video input from Gstreamer translator to OpenCV matrix 
    Copyright (C) 2013  Karolis Tarasauskas <karolis.tarasauskas@gmail.com>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/


#include "video_in.h"

VideoIN::VideoIN()
{
	irenginys = "/dev/video1";
	return;
}

void VideoIN::create_pipeline()
{

    qDebug("Creating pipeline with :");
    qDebug() << irenginys;
    
    source = QGst::ElementFactory::make("v4l2src");
    qDebug() << "middle";
    source->setProperty("device",irenginys);
    filtr = QGst::ElementFactory::make("capsfilter");
    filtr->setProperty("caps",QGst::Caps::fromString("image/jpeg,width=640,height=480,framerate=30/1"));
    ffmpeg = QGst::ElementFactory::make("ffmpegcolorspace");
    filtr2 = QGst::ElementFactory::make("capsfilter");
    filtr2->setProperty("caps",QGst::Caps::fromString("video/x-raw-rgb,width=640,height=480,framerate=30/1")); 
    jpegdec = QGst::ElementFactory::make("jpegdec");
    sink = QGst::ElementFactory::make("appsink");
    app_sink.setElement(sink);
    app_sink.setMaxBuffers(1);
    app_sink.enableDrop(true);
    
    pipeline = QGst::Pipeline::create();
    pipeline->add(source, filtr, jpegdec, ffmpeg, filtr2, sink);
    pipeline->linkMany(source, filtr, jpegdec, ffmpeg, filtr2, sink);
    qDebug("Pipeline created");
};

void VideoIN::get_frame(cv::Mat *destination)
{
    buferis = app_sink.pullBuffer();
    cv::Mat output(cv::Size(640,480),CV_8UC3,(void*)buferis->data(),0);
    if(output.empty())
    {
        qDebug("camera stream is empty");
        output = cv::Scalar(0,0,0);
    };
    cv::cvtColor(output,output,CV_RGB2BGR);
    output.copyTo(*destination);

}

void VideoIN::start_stream()
{
    pipeline->setState(QGst::StatePlaying);
    qDebug("Started stream");
};

void VideoIN::flip_image()
{
  flip=!flip;
};
