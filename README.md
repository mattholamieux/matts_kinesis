This script is a modification of @jaseknighter's kinesis script, which was written for the 2025 habitus workshops and is meant to be tinkered with by folks with a beginning to intermediate level of norns-scripting  experience (e.g. me)

Major additions to the original kinesis script include an additional sun mode and added grid support. 

As in the original script, use E2 and E3 to change values for the selected parameter for the respective sun. Use E2 and E3 while holding K1 to switch between params for the respective sun. Please see the github page for the original script for more in-depth explanation of kinesis: https://github.com/jaseknighter/kinesis

Huge shoutout to @jaseknighter for answering all my questions during the habitus workshop in Santa Cruz. I learned a ton by working with(in) kinesis with their support!

# Installation
* `;install https://github.com/mattholamieux/matts_kinesis`
* Restart norns 
* Load the script


# Differences from original kinesis script

* This version of kinesis includes two sun modes, which are not swappable:
  * The LEFT SUN is set to granulate audio from norns input (this is sun mode 2 from the original kinesis) and includes the following parameters:
    * "sp": `engine.speed` (the rate of the grain synth's playhead.default: 1)
    * "dn": `engine.density` (the rate of grain generation. default: 1 grain per second)
    * "ps": `engine.pos` (the playhead's position in the buffer)
    * "sz": `engine.size` (the size of the granulated sample taken from the buffer. default: 0.1)
    * "jt": `engine.jitter` (causes the playhead to randomly jump within the buffer. default: 0)
    * "ge": `engine.env_shape` (the shape of the grain envelope...see below for details. default: 6)
    * "rl": `engine.rec_level` (the amount of new audio recording into the buffer. default: 1)
    * "pl": `engine.pre_level` (the amount of existing audio to be retained the buffer. default: 0)
  * The RIGHT SUN processes the audio from the left sun via a stereo varispeed delay, using softcut. It includes the following parameters:
    * "l1": `length one` (the length of the delay for the first stereo channel)
    * "l2": `length two` (the length of the delay for the second stereo channel)
    * "r1": `rate one` (the rate of the first channel)
    * "r2": `rate two` (the rate of the second channel)
    * "c1": `cutoff one` (filter cutoff frequency of first channel)
    * "c2": `cutoff two` (filter cutoff frequency of second channel)
    * "fb": `feedback` (the amount of audio passed back into the record buffer. at 100% this freezes the contents of the softcut buffer and stops recording new audio)
    * "sp": `spread` (the pan positions of the two channels)
* All parameters of both suns can be changed using the norns encoders (as in the original script), but they can also be changed using a connected grid. With a grid connected, each column acts like a fader. Columns 1-8 control the parameters of the LEFT SUN, while columns 9-16 control parameters of the RIGHT SUN. 
* Recording param changes is slightly altered in this version of kinesis:
  * Press K2 or K3 to enable recording of param changes to the LEFT SUN or RIGHT SUN respectively, either via the encoders or the grid. 
  * Press K2 or K3 again to end recording for the respective sun and begin playing back automation.
  * Repeat to overdub additional param changes.
  * Press K2 or K3 while holding K1 to clear param automation for the respective sun.